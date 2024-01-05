defmodule BelayBrokerageTest do
  use BelayBrokerage.DataCase

  alias BelayBrokerage.Investor

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
end
