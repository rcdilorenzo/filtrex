defmodule Filtrex.SampleModel do
  use Ecto.Schema

  schema "sample_models" do
    field :title
    field :date_column,     :date
    field :datetime_column, :naive_datetime
    field :upvotes,         :integer
    field :rating,          :float
    field :comments

    timestamps()
  end

  def filtrex_config do
    [%Filtrex.Type.Config{type: :number, keys: ~w(id), options: %{allowed_values: [1]}},
     %Filtrex.Type.Config{type: :text, keys: ~w(title)},
     %Filtrex.Type.Config{type: :date, keys: ~w(date_column)},
     %Filtrex.Type.Config{type: :number, keys: ~w(upvotes)},
     %Filtrex.Type.Config{type: :boolean, keys: ~w(flag)},
     %Filtrex.Type.Config{type: :datetime, keys: ~w(datetime_column)},
     %Filtrex.Type.Config{type: :number, keys: ~w(rating), options: %{allow_decimal: true}}]
  end
end
