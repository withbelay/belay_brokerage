defmodule BelayBrokerageTest do
  use BelayBrokerage.DataCase

  alias BelayBrokerage.Investor
  alias BelayBrokerage.Holding

  alias BelayBrokerage.TestTransactionHandler

  import BelayBrokerage.Factory

  test "all_investors/1" do
    investor = insert!(:investor)

    assert investor in BelayBrokerage.all_investors(@default_tenant)
  end

  describe "create_investors/2" do
    test "inserts investor" do
      investor = build(:investor)

      assert {:ok, %Investor{} = received_investor} = BelayBrokerage.create_investor(@default_tenant, investor)

      assert investor.first_name == received_investor.first_name
      assert investor.address_1 == received_investor.address_1
      assert investor.last_name == received_investor.last_name
      assert investor.address_2 == received_investor.address_2
      assert investor.city == received_investor.city
      assert investor.region == received_investor.region
      assert investor.postal_code == received_investor.postal_code
      assert investor.email == received_investor.email
      assert investor.phone == received_investor.phone
    end

    test "returns changeset on error" do
      investor = :investor |> build() |> Map.put(:first_name, 123)

      assert {:error, %Ecto.Changeset{}} = BelayBrokerage.create_investor(@default_tenant, investor)
    end
  end

  describe "get_investor/2" do
    test "retrieves inserted investor" do
      investor = insert!(:investor)

      assert BelayBrokerage.get_investor(@default_tenant, investor.id) == investor
    end

    test "returns nil when no investor exists" do
      assert BelayBrokerage.get_investor(@default_tenant, "some id") == nil
    end
  end

  describe "get_holdings/2" do
    test "retrieves all holdings" do
      investor_id = "investor_id"
      aapl_holding = insert!(:holding, %{investor_id: investor_id, sym: "AAPL"})
      msft_holding = insert!(:holding, %{investor_id: investor_id, sym: "MSFT"})

      holdings = BelayBrokerage.get_holdings(@default_tenant, investor_id)
      assert aapl_holding in holdings
      assert msft_holding in holdings
    end
  end

  describe "holding_transaction/4" do
    test "when no holding exists, insert one" do
      investor_id = "id"
      qty = Decimal.from_float(1.0)

      assert {:ok, %Holding{}} = BelayBrokerage.holding_transaction(@default_tenant, investor_id, "AAPL", qty)

      assert [holding] = BelayBrokerage.get_holdings(@default_tenant, investor_id)
      assert holding.sym == "AAPL"
      assert holding.investor_id == investor_id
      assert holding.qty == qty
    end

    test "when a holding exists, increment or decrement qty to existing one" do
      %{investor_id: investor_id, sym: sym, qty: existing_qty} = insert!(:holding)
      delta_qty = Decimal.from_float(1.0)

      assert {:ok, %Holding{}} =
               BelayBrokerage.holding_transaction(@default_tenant, investor_id, sym, delta_qty)

      assert [holding] = BelayBrokerage.get_holdings(@default_tenant, investor_id)
      assert holding.qty == Decimal.add(existing_qty, delta_qty)
    end

    test "when a holding exists, and new qty is now 0, delete holding" do
      %{investor_id: investor_id, sym: sym} = insert!(:holding, %{qty: Decimal.from_float(1.0)})
      delta_qty = Decimal.from_float(-1.0)

      assert {:ok, %Holding{}} =
               BelayBrokerage.holding_transaction(@default_tenant, investor_id, sym, delta_qty)

      assert BelayBrokerage.get_holdings(@default_tenant, investor_id) == []
    end

    test "pushes a rabbit message when called successfully" do
      start_supervised!({TestTransactionHandler, self()})

      investor_id = "id"
      sym = "AAPL"
      qty = Decimal.from_float(1.0)

      assert {:ok, %Holding{}} = BelayBrokerage.holding_transaction(@default_tenant, investor_id, sym, qty)

      assert_receive {:handle_message,
                      %{decoded_payload: %{"investor_id" => ^investor_id, "sym" => ^sym, "qty" => "1.0"}}}
    end

    test "does not push a rabbit message when called unsuccessfully" do
      start_supervised!({TestTransactionHandler, self()})

      assert {:error, %Ecto.Changeset{errors: [qty: {"is invalid", _}]}} =
               BelayBrokerage.holding_transaction(@default_tenant, "id", "AAPL", "not a decimal")

      refute_receive {:handle_message, _}
    end
  end
end
