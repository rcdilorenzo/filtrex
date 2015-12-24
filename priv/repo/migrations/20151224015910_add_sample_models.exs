defmodule Filtrex.Repo.Migrations.AddSampleModels do
  use Ecto.Migration

  def change do
    create table(:sample_models) do
      add :title, :string
      add :date_column, :date
      add :time_column, :time
      add :comments, :text

      timestamps
    end
  end
end
