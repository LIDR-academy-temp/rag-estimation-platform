module ApplicationHelper
  include Pagy::Frontend

  def format_currency(amount, currency = "EUR")
    number_to_currency(amount, unit: "€", format: "%n%u", separator: ",", delimiter: ".")
  end

  def confidence_color(score)
    if score >= 0.7
      "text-success"
    elsif score >= 0.5
      "text-warning"
    else
      "text-destructive"
    end
  end

  def score_color(score)
    if score >= 0.8
      "text-success"
    elsif score >= 0.65
      "text-warning"
    else
      "text-muted-foreground"
    end
  end

  def score_bg_color(score)
    if score >= 0.8
      "bg-success/10 text-success"
    elsif score >= 0.65
      "bg-warning/10 text-warning"
    else
      "bg-muted text-muted-foreground"
    end
  end

  def chunk_type_color(type)
    {
      "project_overview" => "bg-primary",
      "scope_block" => "bg-info",
      "line_item" => "bg-success",
      "phase" => "bg-warning",
      "team_conditions" => "bg-destructive"
    }[type.to_s] || "bg-muted"
  end
end
