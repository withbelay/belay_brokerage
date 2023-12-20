defmodule BelayBrokerage.SimpleTypedSchema do
  @moduledoc """
  Create `new` and `new!` functions for `typed_embedded_schema` via a `def_new` macro

  ## Rationale

  Ecto changeset functions can be used to create validated structs.  Normally, these functions are largely boilerplate
  and the noise generated make it easy to overlook changes in the defined fields or avoid doing validation
  altogether.

  The `def_new` macro will define `new` and `new!` functions for struct construction and validation.

  The `new` function takes a struct or an optional map of attributes, does Ecto.cast of all values provided fields,
  validates any required
  fields, and does `Ecto.apply_action` to validate the changeset.  Returning `{:ok, <struct>}` if everything is OK,
  `{:error, <changeset>}` if there were issues with `cast` or validation.  If a struct is passed to the `new` function,
  it will be converted to a map

  The `new!` function calls `new` and returns the struct if successful, and raises if not

  ## Macro options

  The `def_new` macro accepts a Keyword options list to control default values and required fields

  - `required:` - an atom or list of atoms for the fields that are required.  The special atom of `:all` indicates that
      all defined fields are required, whereas the atom `:none` disables required field validation
  - `not_required:` - an atom or list of atoms specifying which fields, of all defined, that are not required.
  - `default:` - a tuple or list of tuples of the form `{:field, MFA-tuple}` or `{:field, <constant value>} that
      specify default values for fields missing in the provided attributes map.

  ## Examples

  ```elixir
  typed_embedded_schema do
    field(:uuid, Ecto.UUID)
    field(:event, Belay.Ecto.Any)
    field(:event_array, {:array, Belay.Ecto.Any})
    field(:qty, :decimal)
  end
  ```

  def_new(not_required: [:uuid, :event, :event_array])
  def_new(required: :all)
  def_new(required: :none)
  def_new(required: [:qty])
  def_new(required: :qty)
  def_new(required: :qty, default: [{:uuid, {Ecto.UUID, :generate, []}}, {:event, :before}])
  """
  import Ecto.Changeset

  defmacro __using__(_opts) do
    quote location: :keep do
      use TypedEctoSchema
      import Ecto.Changeset
      import unquote(__MODULE__)

      @primary_key false
    end
  end

  # credo:disable-for-next-line
  defmacro def_new(opts \\ []) do
    quote do
      # if `@req_attrs` already specified then don't override
      unless Module.has_attribute?(__MODULE__, :req_attrs) do
        Module.register_attribute(__MODULE__, :req_attrs, accumulate: false)

        # `required:` - declarative set of fields that are required, if `:all` then all declared fields are required
        # `not_required:` - set of declared fields that are NOT required
        cond do
          required = Keyword.get(unquote(opts), :required) ->
            Module.put_attribute(__MODULE__, :req_attrs, {:required, required})

          not_required = Keyword.get(unquote(opts), :not_required) ->
            Module.put_attribute(__MODULE__, :req_attrs, {:not_required, not_required})

          true ->
            nil
        end
      end

      # accept a list of field default specifiers of form: `{field, <mfa-tuple>}`
      Module.register_attribute(__MODULE__, :default_fields, accumulate: false)
      Module.put_attribute(__MODULE__, :default_fields, Keyword.get(unquote(opts), :default, []))

      @spec new(struct(), map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
      def new(base_struct, attrs) when is_struct(base_struct) do
        base_struct
        |> Map.from_struct()
        |> Map.merge(attrs)
        |> new()
      end

      @spec new(struct(), map()) :: t()
      def new!(base_struct, attrs) when is_struct(base_struct) do
        case new(base_struct, attrs) do
          {:ok, val} -> val
          {:error, cs} -> raise "Invalid #{__MODULE__}.new!(): #{inspect(cs.errors)}"
        end
      end

      @spec new(map() | struct()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
      def new(), do: new(%{})

      def new(attrs) when is_struct(attrs) do
        attrs
        |> Map.from_struct()
        |> new()
      end

      def new(attrs) do
        changeset(%__MODULE__{}, attrs)
        |> apply_action(:new)
      end

      @spec new!(map() | struct()) :: t()
      def new!(), do: new!(%{})

      def new!(attrs) do
        case new(attrs) do
          {:ok, val} -> val
          {:error, cs} -> raise "Invalid #{__MODULE__}.new!(): #{inspect(cs.errors)}"
        end
      end

      def changeset(%__MODULE__{} = existing, attrs) when is_struct(attrs),
        do: changeset(existing, Map.from_struct(attrs))

      def changeset(%__MODULE__{} = existing, attrs) do
        fields = __MODULE__.__schema__(:fields) ++ __MODULE__.__schema__(:virtual_fields)
        fields = Enum.reject(fields, &(&1 in __MODULE__.__schema__(:embeds)))

        existing
        |> cast(attrs, fields)
        |> maybe_cast_embeds(attrs)
        |> default_fields(@default_fields)
        |> do_required(@req_attrs, fields)
      end

      def maybe_cast_embeds(changeset, attrs) do
        case __MODULE__.__schema__(:embeds) do
          [] ->
            changeset

          embeds ->
            Enum.reduce(embeds, changeset, fn field, changeset -> cast_embed(changeset, field) end)
        end
      end
    end
  end

  @to_df_conversion_mapping %{
    Money.Ecto.Amount.Type => :float,
    # TODO: Nice to have feature, problematic to implement
    # Ecto.Enum => :category,
    :decimal => :float,
    :float => :float,
    :integer => :integer,
    :string => :string,
    :binary => :binary,
    :boolean => :boolean,
    :date => :date,
    :time => :time,
    :datetime => {:datetime, :millisecond},
    :naive_datetime => {:datetime, :millisecond},
    :naive_datetime_usec => {:datetime, :millisecond},
    :utc_datetime => {:datetime, :millisecond},
    :utc_datetime_usec => {:datetime, :millisecond}
  }

  defmacro def_dataframe(opts \\ []) do
    quote location: :keep do
      require Explorer.DataFrame, as: DF

      @spec from_dataframe(DF.t()) :: [__MODULE__.t()]
      def from_dataframe(df) do
        if not function_exported?(__MODULE__, :new!, 1) do
          raise "Could not detect #{__MODULE__}.new!/1 function, #{__MODULE__}.from_dataframe/1 requires #{__MODULE__}.new!/1"
        end

        money_fields = get_fields(@ecto_changeset_fields, Money.Ecto.Amount.Type)
        decimal_fields = get_fields(@ecto_changeset_fields, :decimal)

        df
        |> DF.to_rows()
        |> Enum.map(fn df_row ->
          df_row
          |> convert_df_row_fields(money_fields, &Belay.ToMoney.to_money/1)
          |> convert_df_row_fields(decimal_fields, &Belay.ToDecimal.to_decimal/1)
          |> __MODULE__.new!()
        end)
      end

      @spec to_dataframe(__MODULE__.t() | [__MODULE__.t()]) :: DF.t()
      def to_dataframe([]), do: empty_df()

      def to_dataframe(%__MODULE__{} = struct) do
        to_dataframe([struct])
      end

      def to_dataframe(structs) when is_list(structs) do
        money_fields = get_fields(@ecto_changeset_fields, Money.Ecto.Amount.Type)
        decimal_fields = get_fields(@ecto_changeset_fields, :decimal)

        structs
        |> Enum.map(fn struct ->
          struct
          |> Map.from_struct()
          |> Map.take(dataframe_fields())
          |> convert_struct_fields(money_fields, fn money -> money.amount / 100 end)
          |> convert_struct_fields(decimal_fields, &Decimal.to_float/1)
        end)
        |> DF.new(dtypes: dtypes())
      end

      @spec dtypes() :: list()
      def dtypes() do
        @ecto_changeset_fields
        |> Enum.filter(fn {name, _type} -> name in dataframe_fields() end)
        |> Enum.map(fn {name, type} -> {name, to_df_type(type)} end)
        |> Enum.reverse()
      end

      @spec empty_df() :: DF.t()
      def empty_df() do
        dtypes = dtypes()

        dtypes
        |> Enum.map(fn {name, _dtype} -> {name, []} end)
        |> DF.new(dtypes: dtypes)
      end

      defp dataframe_fields() do
        Keyword.get(unquote(opts), :dataframe_fields, __MODULE__.__schema__(:fields))
      end
    end
  end

  def convert_df_row_fields(df_row, convert_fields, convert_callback) do
    Enum.reduce(convert_fields, df_row, fn convert_field, df_row ->
      convert_field = Atom.to_string(convert_field)
      Map.replace(df_row, convert_field, convert_callback.(df_row[convert_field]))
    end)
  end

  def convert_struct_fields(map, convert_fields, convert_callback) do
    Enum.reduce(convert_fields, map, fn convert_field, map ->
      Map.replace(map, convert_field, convert_callback.(map[convert_field]))
    end)
  end

  def get_fields(ecto_changeset_fields, type) do
    ecto_changeset_fields
    |> Enum.filter(fn {_name, field_type} -> field_type == type end)
    |> Enum.map(fn {name, _type} -> name end)
  end

  def to_df_type(type) do
    if type == Ecto.Enum do
      raise "Ecto.Enum is not supported"
    end

    @to_df_conversion_mapping[type]
  rescue
    exception ->
      reraise(exception, "Check if #{inspect(type)} is a valid Explorer.DataFrame dtype")
  end

  def default_fields(%Ecto.Changeset{} = changeset, defaults) do
    Enum.reduce(List.wrap(defaults), changeset, &cast_default/2)
  end

  defp cast_default({field, {m, f, a}}, changeset) do
    value = get_change(changeset, field, apply(m, f, a))

    change(changeset, %{field => value})
  end

  defp cast_default({field, default_value}, changeset) do
    value = get_change(changeset, field, default_value)

    change(changeset, %{field => value})
  end

  def do_required(changeset, {:required, :none}, _all_fields), do: changeset

  def do_required(changeset, {:required, :all}, all_fields),
    do: validate_required(changeset, all_fields)

  def do_required(changeset, {:required, fields}, _all_fields),
    do: validate_required(changeset, fields)

  def do_required(changeset, {:not_required, fields}, all),
    do: validate_required(changeset, all -- List.wrap(fields))

  def do_required(changeset, req_attrs, _all), do: validate_required(changeset, req_attrs)
end
