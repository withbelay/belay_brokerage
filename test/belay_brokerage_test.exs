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

  describe "create_investor/3" do
    test "when investor has uid and email, an Investor and an AuthAccount is inserted" do
      %{uid: uid, email: email} = build(:auth_account)

      assert {:ok, %Investor{id: investor_id, auth_accounts: [auth_account]}} =
               BelayBrokerage.create_investor(@default_tenant, uid, email)

      assert %AuthAccount{investor_id: ^investor_id, uid: ^uid, email: ^email, is_primary: true} = auth_account
    end

    test "returns changeset on error" do
      invalid_email = 123
      assert {:error, %Ecto.Changeset{}} = BelayBrokerage.create_investor(@default_tenant, "valid uid", invalid_email)
    end
  end

  describe "update_investor/3" do
    test "when field changes value, existing investor is updated" do
      %{id: investor_id} = investor = insert!(:investor)

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

    test "when fields changes to an invalid value, returns {:error, Ecto.Changeset}" do
      %{id: investor_id} = insert!(:investor)
      invalid_first_name = 123

      assert {:error, %Ecto.Changeset{}} =
               BelayBrokerage.update_investor(@default_tenant, investor_id, %{first_name: invalid_first_name})
    end

    test "when investor doesn't exist, returns {:error, :investor_not_found}" do
      assert {:error, :investor_not_found} =
               BelayBrokerage.update_investor(@default_tenant, "some investor_id", %{})
    end
  end

  describe "get_investor/2" do
    test "retrieves inserted investor" do
      %{auth_accounts: [%{email: primary_email}]} = investor = insert!(:investor)

      expected_investor = %{investor | primary_email: primary_email}

      assert @default_tenant |> BelayBrokerage.get_investor(investor.id) |> Repo.preload([:auth_accounts]) ==
               expected_investor
    end

    test "returns nil when no investor exists" do
      assert BelayBrokerage.get_investor(@default_tenant, "some id") == nil
    end
  end

  describe "get_investor_by_email/2" do
    test "retrieves inserted investor" do
      %{auth_accounts: [%{email: primary_email}]} = investor = insert!(:investor)

      expected_investor = %{investor | primary_email: primary_email}

      assert @default_tenant
             |> BelayBrokerage.get_investor_by_email(primary_email)
             |> Repo.preload([:auth_accounts]) ==
               expected_investor
    end
  end

  describe "get_investor_by_item_id/2" do
    test "retrieves inserted investor" do
      %{auth_accounts: [%{email: primary_email}]} = investor = insert!(:investor)

      expected_investor = %{investor | primary_email: primary_email}

      assert @default_tenant
             |> BelayBrokerage.get_investor_by_item_id(investor.item_id)
             |> Repo.preload([:auth_accounts]) ==
               expected_investor
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
