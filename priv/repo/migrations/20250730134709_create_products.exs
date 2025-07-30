defmodule MakananSegar.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string, null: false
      add :description, :text, null: false
      add :category, :string, null: false
      add :price, :decimal, precision: 10, scale: 2, null: false
      add :image, :string
      add :expires_at, :utc_datetime, null: false
      add :is_active, :boolean, default: true, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:products, [:user_id])
    create index(:products, [:category])
    create index(:products, [:expires_at])
    create index(:products, [:is_active])
    create index(:products, [:user_id, :is_active])
  end
end
