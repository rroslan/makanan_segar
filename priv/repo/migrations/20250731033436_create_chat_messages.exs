defmodule MakananSegar.Repo.Migrations.CreateChatMessages do
  use Ecto.Migration

  def change do
    create table(:chat_messages) do
      add :content, :text, null: false
      add :sender_name, :string
      add :sender_email, :string
      add :product_id, references(:products, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :nilify_all)
      add :is_vendor_reply, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:chat_messages, [:product_id])
    create index(:chat_messages, [:user_id])
    create index(:chat_messages, [:product_id, :inserted_at])
  end
end
