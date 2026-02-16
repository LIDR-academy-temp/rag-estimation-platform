module IconHelper
  def icon(name, classes: "h-4 w-4")
    render partial: "shared/icons/#{name}", locals: { classes: classes }
  end
end
