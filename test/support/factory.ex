defmodule BelayBrokerage.Factory do
  alias BelayBrokerage.Repo
  alias BelayBrokerage.Holding
  alias BelayBrokerage.Investor

  @default_tenant Application.compile_env!(:belay_brokerage, :tenants) |> List.first()

  def build(:investor) do
    %Investor{
      id: "id",
      first_name: "John",
      last_name: "Doe",
      address_1: "2100 Market St",
      address_2: "Floor 5",
      city: "Philadelphia",
      region: "PA",
      postal_code: "19103",
      email: "johndoe@email.com",
      phone: "123-123-1234"
    }
  end

  def build(:holding) do
    %Holding{
      investor_id: "id",
      sym: "AAPL",
      qty: Decimal.from_float(1.0)
    }
  end

  def build(factory_name, attributes) do
    factory_name |> build() |> struct!(attributes)
  end

  def insert!(factory_name, attributes \\ []) do
    tenant = Keyword.get(attributes, :tenant, @default_tenant)
    factory_name |> build(attributes) |> Repo.insert!(prefix: tenant)
  end
end
