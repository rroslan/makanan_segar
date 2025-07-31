defmodule MakananSegar.Repo.Migrations.CreateMessageReads do
  use Ecto.Migration

  def change do
    create table(:message_reads) do
      add :read_at, :utc_datetime, null: false
      add :message_id, references(:chat_messages, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:message_reads, [:message_id])
    create index(:message_reads, [:user_id])

    # Ensure a user can only mark a message as read once
    create unique_index(:message_reads, [:message_id, :user_id],
           name: :message_reads_message_id_user_id_index)
  end
end
