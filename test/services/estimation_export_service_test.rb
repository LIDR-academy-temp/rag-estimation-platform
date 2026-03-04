require "test_helper"

class EstimationExportServiceTest < ActiveSupport::TestCase
  setup do
    @estimation = estimations(:completed_estimation)
    @result = EstimationExportService.new(@estimation).call
  end

  test "top-level structure has quote, source and ingested_by" do
    assert_equal %i[quote source ingested_by].sort, @result.keys.sort
    assert_equal "platform_export", @result[:source]
    assert_equal "antonio@example.com", @result[:ingested_by]
  end

  test "quote contains project, scope_blocks, totals and team_conditions" do
    quote = @result[:quote]
    assert_equal %i[project scope_blocks totals team_conditions].sort, quote.keys.sort
  end

  test "project maps title, currency, technologies and confidence" do
    project = @result[:quote][:project]
    assert_equal "Estimación Completa", project[:title]
    assert_equal "EUR", project[:currency]
    assert_equal ["Ruby", "Rails"], project[:technologies]
    assert_equal 0.85, project[:confidence]
  end

  test "scope_blocks maps functional blocks with items and subtotals" do
    blocks = @result[:quote][:scope_blocks]
    assert_equal 2, blocks.length

    auth_block = blocks.find { |b| b[:name] == "Autenticación" }
    assert_not_nil auth_block
    assert_equal 2, auth_block[:items].length
    assert_equal ["Ruby", "Rails"], auth_block[:technologies]
  end

  test "each item has hours with three estimates, unit_price and total" do
    auth_block = @result[:quote][:scope_blocks].find { |b| b[:name] == "Autenticación" }
    login_item = auth_block[:items].find { |i| i[:name] == "Login con JWT" }

    assert_equal({ optimistic: 8.0, expected: 16.0, pessimistic: 24.0 }, login_item[:hours])
    assert_equal 130.0, login_item[:unit_price]
    assert_equal({ optimistic: 1040.0, expected: 2080.0, pessimistic: 3120.0 }, login_item[:total])
  end

  test "effective_rate uses task rate when present, global_rate when nil" do
    auth_block = @result[:quote][:scope_blocks].find { |b| b[:name] == "Autenticación" }

    login_item = auth_block[:items].find { |i| i[:name] == "Login con JWT" }
    assert_equal 130.0, login_item[:unit_price] # task-level rate

    oauth_item = auth_block[:items].find { |i| i[:name] == "OAuth Integration" }
    assert_equal 120.0, oauth_item[:unit_price] # inherited global_rate
  end

  test "scope_block subtotals are computed correctly" do
    auth_block = @result[:quote][:scope_blocks].find { |b| b[:name] == "Autenticación" }

    assert_equal({ optimistic: 24.0, expected: 40.0, pessimistic: 64.0 }, auth_block[:subtotal_hours])

    # login: 8*130=1040, 16*130=2080, 24*130=3120
    # oauth: 16*120=1920, 24*120=2880, 40*120=4800
    assert_equal({ optimistic: 2960.0, expected: 4960.0, pessimistic: 7920.0 }, auth_block[:subtotal_cost])
  end

  test "totals come from estimation stored values" do
    totals = @result[:quote][:totals]
    assert_equal({ optimistic: 100.0, expected: 150.0, pessimistic: 200.0 }, totals[:hours])
    assert_equal({ optimistic: 12000.0, expected: 18000.0, pessimistic: 24000.0 }, totals[:cost])
  end

  test "team_conditions includes base_rate and currency" do
    tc = @result[:quote][:team_conditions]
    assert_equal 120.0, tc[:base_rate]
    assert_equal "EUR", tc[:currency]
  end

  test "ingest compatibility: quote.project.title is present" do
    assert @result.dig(:quote, :project, :title).present?
  end

  test "ingest compatibility: scope_blocks have technologies" do
    @result[:quote][:scope_blocks].each do |block|
      assert block[:technologies].is_a?(Array), "scope_block #{block[:name]} missing technologies"
    end
  end
end
