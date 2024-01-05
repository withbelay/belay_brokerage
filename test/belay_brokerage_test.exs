defmodule BelayBrokerageTest do
  use BelayBrokerage.DataCase

  import BelayBrokerage.Factory

  test "all_investors" do
    investor = insert!(:investor)

    assert investor in BelayBrokerage.all_investors(@default_tenant)
  end
end
