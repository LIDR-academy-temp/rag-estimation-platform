class EstimationPdfService
  Prawn::Fonts::AFM.hide_m17n_warning = true

  NAVY = "1a2332"
  DARK_TEXT = "333333"
  GRAY_TEXT = "666666"
  TABLE_HEADER_BG = "f0f0f0"
  SUBTOTAL_BG = "eef2ff"

  def initialize(estimation)
    @estimation = estimation
  end

  def call
    pdf = Prawn::Document.new(page_size: "A4", margin: [40, 40, 50, 40])
    pdf.font_size 9

    render_header(pdf)
    render_metadata(pdf)
    render_technologies(pdf)
    render_blocks(pdf)
    render_totals(pdf)
    render_references(pdf)
    render_page_numbers(pdf)

    pdf.render
  end

  private

  def render_header(pdf)
    pdf.fill_color NAVY
    pdf.text "Presupuesto de Estimacion", size: 20, style: :bold
    pdf.move_down 6
    pdf.fill_color DARK_TEXT
    pdf.text @estimation.title, size: 14, style: :bold
    if @estimation.description.present?
      pdf.move_down 4
      pdf.fill_color GRAY_TEXT
      pdf.text @estimation.description, size: 9
    end
    pdf.move_down 12
    pdf.fill_color DARK_TEXT
  end

  def render_metadata(pdf)
    date = @estimation.created_at.strftime("%d/%m/%Y")
    rate = format_number(@estimation.global_rate)
    currency = @estimation.currency
    confidence = @estimation.confidence_score ? "#{(@estimation.confidence_score * 100).round}%" : "N/A"

    pdf.text "Fecha: #{date}  |  Moneda: #{currency}  |  Tarifa base: #{rate} #{currency}/h  |  Confianza: #{confidence}",
      size: 9, color: GRAY_TEXT
    pdf.move_down 10
  end

  def render_technologies(pdf)
    techs = Array(@estimation.technologies)
    return if techs.empty?

    pdf.text "Tecnologias: #{techs.join(', ')}", size: 9, color: GRAY_TEXT
    pdf.move_down 12
  end

  def render_blocks(pdf)
    @estimation.functional_blocks.includes(:tasks).order(:position).each do |block|
      render_block(pdf, block)
    end
  end

  def render_block(pdf, block)
    pdf.fill_color NAVY
    pdf.text block.name, size: 12, style: :bold
    pdf.move_down 6
    pdf.fill_color DARK_TEXT

    currency = @estimation.currency
    header = ["Tarea", "Tarifa", "Horas", "Coste"]

    rows = block.tasks.order(:position).map do |task|
      rate = task.effective_rate
      [
        task.name,
        "#{format_number(rate)} #{currency}",
        format_number(task.hours_expected),
        "#{format_number(task.cost(:expected))} #{currency}"
      ]
    end

    subtotal_row = [
      { content: "Subtotal #{block.name}", colspan: 2, font_style: :bold },
      format_number(block.total_hours_expected),
      "#{format_number(block.total_cost(:expected))} #{currency}"
    ]

    table_data = [header] + rows + [subtotal_row]

    pdf.table(table_data, width: pdf.bounds.width, cell_style: { size: 8, padding: [4, 6] }) do |t|
      t.row(0).font_style = :bold
      t.row(0).background_color = TABLE_HEADER_BG
      t.row(-1).background_color = SUBTOTAL_BG
      t.row(-1).font_style = :bold
      t.columns(1..-1).align = :right
      t.columns(0).width = 200
    end

    pdf.move_down 14
  end

  def render_totals(pdf)
    pdf.fill_color NAVY
    pdf.text "Resumen Total", size: 14, style: :bold
    pdf.move_down 8
    pdf.fill_color DARK_TEXT

    currency = @estimation.currency
    totals_data = [
      ["", "Esperado"],
      ["Horas totales", format_number(@estimation.total_hours_expected)],
      ["Coste total", "#{format_number(@estimation.total_cost_expected)} #{currency}"]
    ]

    table_width = 260
    x_offset = (pdf.bounds.width - table_width) / 2

    pdf.indent(x_offset) do
      pdf.table(totals_data, width: table_width, cell_style: { size: 9, padding: [5, 8] }) do |t|
        t.row(0).font_style = :bold
        t.row(0).background_color = TABLE_HEADER_BG
        t.columns(1..-1).align = :right
        t.row(1..2).columns(0).font_style = :bold
      end
    end

    pdf.move_down 16
  end

  def render_references(pdf)
    refs = @estimation.references.order(similarity_score: :desc)
    return if refs.empty?

    pdf.fill_color NAVY
    pdf.text "Proyectos de Referencia", size: 12, style: :bold
    pdf.move_down 6
    pdf.fill_color DARK_TEXT

    refs.each do |ref|
      similarity = "#{(ref.similarity_score * 100).round}%"
      cost_str = ref.cost ? " — #{format_number(ref.cost)} #{ref.currency}" : ""
      pdf.text "\u2022 #{ref.title} (similitud: #{similarity}#{cost_str})", size: 9
      if ref.content_preview.present?
        pdf.text "  #{ref.content_preview}", size: 8, color: GRAY_TEXT
      end
      pdf.move_down 3
    end
  end

  def render_page_numbers(pdf)
    pdf.number_pages "Pagina <page> de <total>",
      at: [pdf.bounds.right - 100, -5],
      size: 8,
      color: GRAY_TEXT
  end

  def format_number(value)
    return "0" if value.nil?

    num = value.to_f
    if num == num.to_i
      integer_with_delimiter(num.to_i)
    else
      parts = format("%.2f", num).split(".")
      "#{integer_with_delimiter(parts[0].to_i)},#{parts[1]}"
    end
  end

  def integer_with_delimiter(number)
    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse
  end
end
