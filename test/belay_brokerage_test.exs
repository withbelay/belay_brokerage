defmodule BelayBrokerageTest do
  use BelayBrokerage.DataCase

  alias BelayBrokerage.AuthAccount
  alias BelayBrokerage.Investor
  alias BelayBrokerage.Holding
  alias BelayBrokerage.Repo

  alias BelayBrokerage.TestTransactionHandler

  import BelayBrokerage.Factory
  import ExUnit.CaptureLog

  test "all_investors/1" do
    investor = insert!(:investor)

    investors_with_auth_accounts =
      @default_tenant |> BelayBrokerage.all_investors() |> Repo.preload([:auth_accounts])

    assert investor in investors_with_auth_accounts
  end

  describe "create_investor/2" do
    test "when investor has all data, it's inserted" do
      investor = build(:investor)

      assert {:ok, %Investor{} = received_investor} = BelayBrokerage.create_investor(@default_tenant, investor)

      assert investor.first_name == received_investor.first_name
      assert investor.address_1 == received_investor.address_1
      assert investor.last_name == received_investor.last_name
      assert investor.address_2 == received_investor.address_2
      assert investor.city == received_investor.city
      assert investor.region == received_investor.region
      assert investor.postal_code == received_investor.postal_code
      assert investor.phone == received_investor.phone
      assert investor.access_token == received_investor.access_token
      assert investor.account_id == received_investor.account_id
      assert investor.item_id == received_investor.item_id
    end

    test "returns changeset on error" do
      investor = :investor |> build() |> Map.put(:first_name, 123)

      assert {:error, %Ecto.Changeset{}} = BelayBrokerage.create_investor(@default_tenant, investor)
    end
  end

  describe "update_investor/3" do
    test "when field changes value, existing investor is updated" do
      investor = build(:investor)

      assert {:ok, %Investor{id: investor_id}} = BelayBrokerage.create_investor(@default_tenant, investor)

      updated_investor_attrs = %{city: "new_city", region: "new_region"}

      assert {:ok, %Investor{} = received_investor} =
               BelayBrokerage.update_investor(@default_tenant, investor_id, updated_investor_attrs)

      assert received_investor.first_name == investor.first_name
      assert received_investor.address_1 == investor.address_1
      assert received_investor.last_name == investor.last_name
      assert received_investor.address_2 == investor.address_2
      assert received_investor.city == "new_city"
      assert received_investor.region == "new_region"
      assert received_investor.postal_code == investor.postal_code
      assert received_investor.phone == investor.phone
      assert received_investor.access_token == investor.access_token
      assert received_investor.account_id == investor.account_id
    end
  end

  describe "upsert_auth_account/3" do
    setup do
      %{investor: insert!(:investor, %{auth_accounts: []})}
    end

    test "if AuthAccount with same email and investor_id exists, does nothing", %{investor: %{id: investor_id}} do
      %{uid: uid, email: email} = insert!(:auth_account, %{investor_id: investor_id})
      params = %{uid: Ecto.UUID.generate(), investor_id: investor_id, email: email}

      assert {:ok, _} = BelayBrokerage.upsert_auth_account(@default_tenant, params)
      assert [%AuthAccount{uid: ^uid}] = Repo.all(AuthAccount, prefix: @default_tenant)
    end

    test "if AuthAccount does not exist, add it and set is_primary to true", %{investor: %{id: investor_id}} do
      uid = Ecto.UUID.generate()
      params = %{uid: uid, investor_id: investor_id, email: "some_email@test.com"}

      assert {:ok, %{uid: ^uid, is_primary: true}} =
               BelayBrokerage.upsert_auth_account(@default_tenant, params)
    end

    test "if AuthAccount exists but with different email, add it and set is_primary to false", %{
      investor: %{id: investor_id}
    } do
      insert!(:auth_account, %{investor_id: investor_id})

      uid = Ecto.UUID.generate()
      params = %{uid: uid, investor_id: investor_id, email: "some_email@test.com"}

      assert {:ok, %{uid: ^uid, is_primary: false}} =
               BelayBrokerage.upsert_auth_account(@default_tenant, params)

      assert AuthAccount |> Repo.all(prefix: @default_tenant) |> length() == 2
    end
  end

  describe "get_investor/2" do
    test "retrieves inserted investor" do
      investor = insert!(:investor)

      assert @default_tenant |> BelayBrokerage.get_investor(investor.id) |> Repo.preload([:auth_accounts]) == investor
    end

    test "returns nil when no investor exists" do
      assert BelayBrokerage.get_investor(@default_tenant, "some id") == nil
    end
  end

  describe "get_investor_by_item_id/2" do
    test "retrieves inserted investor" do
      investor = insert!(:investor)

      assert @default_tenant
             |> BelayBrokerage.get_investor_by_item_id(investor.item_id)
             |> Repo.preload([:auth_accounts]) ==
               investor
    end

    test "returns nil when no investor exists" do
      assert BelayBrokerage.get_investor_by_item_id(@default_tenant, "some item_id") == nil
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

      assert {:ok, %Holding{}} =
               BelayBrokerage.holding_transaction(@default_tenant, investor_id, "AAPL", qty, "brokerage")

      assert [holding] = BelayBrokerage.get_holdings(@default_tenant, investor_id)
      assert holding.sym == "AAPL"
      assert holding.investor_id == investor_id
      assert holding.qty == qty
    end

    test "when a holding exists, increment or decrement qty to existing one" do
      %{investor_id: investor_id, sym: sym, qty: existing_qty} = insert!(:holding)
      delta_qty = Decimal.from_float(1.0)

      assert {:ok, %Holding{}} =
               BelayBrokerage.holding_transaction(@default_tenant, investor_id, sym, delta_qty, "brokerage")

      assert [holding] = BelayBrokerage.get_holdings(@default_tenant, investor_id)
      assert holding.qty == Decimal.add(existing_qty, delta_qty)
    end

    test "when a holding exists, and new qty is now 0, delete holding" do
      %{investor_id: investor_id, sym: sym} = insert!(:holding, %{qty: Decimal.from_float(1.0)})
      delta_qty = Decimal.from_float(-1.0)

      assert {:ok, %Holding{}} =
               BelayBrokerage.holding_transaction(@default_tenant, investor_id, sym, delta_qty, "brokerage")

      assert BelayBrokerage.get_holdings(@default_tenant, investor_id) == []
    end

    test "pushes a rabbit message when called successfully" do
      start_supervised!({TestTransactionHandler, self()})

      investor_id = "id"
      sym = "AAPL"
      qty = Decimal.from_float(1.0)

      # When qty is positive
      assert {:ok, %Holding{}} = BelayBrokerage.holding_transaction(@default_tenant, investor_id, sym, qty, "brokerage")

      # type is buy
      assert_receive {:handle_message,
                      %{
                        decoded_payload: %{
                          "investor_id" => ^investor_id,
                          "sym" => ^sym,
                          "delta_qty" => "1.0"
                        }
                      }}

      # When qty is negative
      assert {:ok, %Holding{}} =
               BelayBrokerage.holding_transaction(@default_tenant, investor_id, sym, Decimal.negate(qty), "brokerage")

      # type is sell
      assert_receive {:handle_message,
                      %{
                        decoded_payload: %{
                          "investor_id" => ^investor_id,
                          "sym" => ^sym,
                          "delta_qty" => "-1.0"
                        }
                      }}
    end

    test "does not push a rabbit message when called unsuccessfully" do
      start_supervised!({TestTransactionHandler, self()})

      log =
        capture_log(fn ->
          assert {:error, %Ecto.Changeset{}} =
                   BelayBrokerage.holding_transaction(@default_tenant, "id", "AAPL", "not a decimal", "brokerage")
        end)

      refute_receive {:handle_message, _}
      assert log =~ "Unable to insert/update/delete holding:"
      assert log =~ "errors: [qty: {\"is invalid\""
    end
  end
end
