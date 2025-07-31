defmodule MakananSegar.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      add :status, :string, default: "open", null: false
      add :resolved_at, :utc_datetime
      add :product_id, references(:products, on_delete: :delete_all), null: false
      add :resolved_by_user_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:conversations, [:product_id])
    create index(:conversations, [:resolved_by_user_id])
    create index(:conversations, [:status])
    create index(:conversations, [:product_id, :status])

    # Ensure only one conversation per product
    create unique_index(:conversations, [:product_id], name: :conversations_product_id_unique_index)

    # Add check constraint for valid statuses
    create constraint(:conversations, :valid_status, check: "status IN ('open', 'resolved')")

    # Add check constraint to ensure resolved conversations have resolved_at and resolved_by_user_id
    create constraint(:conversations, :resolved_fields_consistency,
           check: "(status = 'resolved' AND resolved_at IS NOT NULL AND resolved_by_user_id IS NOT NULL) OR (status = 'open' AND resolved_at IS NULL AND resolved_by_user_id IS NULL)")
  end
end
