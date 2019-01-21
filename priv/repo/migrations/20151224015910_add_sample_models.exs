defmodule Filtrex.Repo.Migrations.AddSampleModels do
  use Ecto.Migration

  def change do
    create table(:sample_models) do
      add(:title, :string)
      add(:date_column, :date)
      add(:datetime_column, :naive_datetime)
      add(:upvotes, :integer)
      add(:rating, :float)
      add(:comments, :text)

      timestamps()
    end
  end
end
