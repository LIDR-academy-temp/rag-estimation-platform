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

  test "quote contains all 13 template sections" do
    expected_keys = %i[client project dates currency discount objectives scope_blocks
                       roadmap_phases items team_members conditions notes terms].sort
    assert_equal expected_keys, @result[:quote].keys.sort
  end

  test "client maps name, email and company nil" do
    client = @result[:quote][:client]
    assert_equal "Antonio Pérez", client[:name]
    assert_equal "antonio@example.com", client[:email]
    assert_nil client[:company]
  end

  test "project maps title, subtitle and proposal_date" do
    project = @result[:quote][:project]
    assert_equal "Estimación Completa", project[:title]
    assert_match(/\A\d{4}-\d{2}-\d{2}\z/, project[:proposal_date])
  end

  test "dates has issue_date and valid_until nil" do
    dates = @result[:quote][:dates]
    assert_match(/\A\d{4}-\d{2}-\d{2}\z/, dates[:issue_date])
    assert_nil dates[:valid_until]
  end

  test "currency is at quote level" do
    assert_equal "EUR", @result[:quote][:currency]
  end

  test "placeholder sections are nil" do
    quote = @result[:quote]
    assert_nil quote[:objectives]
    assert_nil quote[:roadmap_phases]
    assert_nil quote[:team_members]
    assert_nil quote[:notes]
    assert_nil quote[:terms]
  end

  test "conditions is nil" do
    assert_nil @result[:quote][:conditions]
  end

  test "scope_blocks maps blocks without legacy fields" do
    blocks = @result[:quote][:scope_blocks]
    assert_equal 2, blocks.length

    blocks.each do |block|
      assert block.key?(:title)
      assert block.key?(:short_description)
      assert block.key?(:detailed_features)
      refute block.key?(:items), "scope_block should not contain items"
      refute block.key?(:name), "scope_block should not contain name"
      refute block.key?(:subtotal_hours), "scope_block should not contain subtotal_hours"
      refute block.key?(:subtotal_cost), "scope_block should not contain subtotal_cost"
    end
  end

  test "scope_block short_description includes block name and task names" do
    auth_block = @result[:quote][:scope_blocks].find { |b| b[:title] == "Autenticación" }
    assert_equal "Autenticación: Login con JWT, OAuth Integration", auth_block[:short_description]
  end

  test "scope_block features lists task names" do
    auth_block = @result[:quote][:scope_blocks].find { |b| b[:title] == "Autenticación" }
    assert_equal ["Login con JWT", "OAuth Integration"], auth_block[:features]
  end

  test "scope_block detailed_features maps tasks with title and description" do
    auth_block = @result[:quote][:scope_blocks].find { |b| b[:title] == "Autenticación" }
    assert_equal 2, auth_block[:detailed_features].length
    auth_block[:detailed_features].each do |df|
      assert df.key?(:title)
      assert df.key?(:description)
      assert_nil df[:description]
    end
  end

  test "items is a flat array of all tasks" do
    items = @result[:quote][:items]
    assert_equal 3, items.length
  end

  test "each item has the correct keys" do
    expected_keys = %i[type name description quantity unit unit_price discount_percent phase].sort
    @result[:quote][:items].each do |item|
      assert_equal expected_keys, item.keys.sort
    end
  end

  test "item values for Login con JWT" do
    item = @result[:quote][:items].find { |i| i[:name] == "Login con JWT" }
    assert_equal "service", item[:type]
    assert_equal 16.0, item[:quantity]
    assert_equal "hora", item[:unit]
    assert_equal 130.0, item[:unit_price]
    assert_equal 0, item[:discount_percent]
    assert_nil item[:phase]
  end

  test "effective_rate falls back to global_rate when task rate is nil" do
    item = @result[:quote][:items].find { |i| i[:name] == "OAuth Integration" }
    assert_equal 120.0, item[:unit_price]
  end

  test "item phase is nil" do
    item = @result[:quote][:items].find { |i| i[:name] == "Componentes UI" }
    assert_nil item[:phase]
  end

  test "ingest compatibility: quote.project.title is present" do
    assert @result.dig(:quote, :project, :title).present?
  end

  test "ingest compatibility: scope_blocks have technologies" do
    @result[:quote][:scope_blocks].each do |block|
      assert block[:technologies].is_a?(Array), "scope_block #{block[:title]} missing technologies"
    end
  end

  test "project includes preferred_stack with frontend and backend" do
    stack = @result[:quote][:project][:preferred_stack]
    assert_equal ["React", "TypeScript"], stack[:frontend]
    assert_equal ["Rails"], stack[:backend]
  end

  test "ingest compatibility: scope_blocks have title and short_description" do
    @result[:quote][:scope_blocks].each do |block|
      assert block[:title].present?, "scope_block missing title"
      assert block[:short_description].present?, "scope_block missing short_description"
    end
  end
end
