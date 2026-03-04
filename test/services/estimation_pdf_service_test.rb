require "test_helper"

class EstimationPdfServiceTest < ActiveSupport::TestCase
  setup do
    @estimation = estimations(:completed_estimation)
  end

  test "generates valid PDF binary" do
    pdf_data = EstimationPdfService.new(@estimation).call
    assert pdf_data.is_a?(String)
    assert pdf_data.start_with?("%PDF")
  end

  test "PDF contains the estimation title" do
    pdf_data = EstimationPdfService.new(@estimation).call
    text = decode_pdf_hex_strings(pdf_data)
    assert_includes text, "Completa"
  end

  test "PDF contains functional block names" do
    pdf_data = EstimationPdfService.new(@estimation).call
    text = decode_pdf_hex_strings(pdf_data)
    # Prawn kerning may split words, so match partial substrings
    assert_includes text, "utenticaci"
    assert_includes text, "ontend"
  end

  test "works without references" do
    @estimation.references.destroy_all
    pdf_data = EstimationPdfService.new(@estimation).call
    assert pdf_data.start_with?("%PDF")
  end

  test "works without confidence_score" do
    @estimation.update_column(:confidence_score, nil)
    pdf_data = EstimationPdfService.new(@estimation).call
    text = decode_pdf_hex_strings(pdf_data)
    assert_includes text, "N/A"
  end

  private

  def decode_pdf_hex_strings(pdf_data)
    # Extract hex-encoded strings from PDF TJ operators and decode them
    raw = pdf_data.force_encoding("ASCII-8BIT")
    texts = raw.scan(/<([0-9a-fA-F]+)>/).map do |match|
      [match[0]].pack("H*").force_encoding("ISO-8859-1").encode("UTF-8")
    end
    texts.join(" ")
  end
end
