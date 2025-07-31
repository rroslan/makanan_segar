defmodule MakananSegar.Chat.MessageRead do
  use Ecto.Schema
  import Ecto.Changeset

  alias MakananSegar.Chat.Message
  alias MakananSegar.Accounts.User

  schema "message_reads" do
    field :read_at, :utc_datetime

    belongs_to :message, Message
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message_read, attrs) do
    message_read
    |> cast(attrs, [:read_at, :message_id, :user_id])
    |> validate_required([:read_at, :message_id, :user_id])
    |> unique_constraint([:message_id, :user_id],
         name: :message_reads_message_id_user_id_index,
         message: "Message already marked as read by this user")
    |> foreign_key_constraint(:message_id)
    |> foreign_key_constraint(:user_id)
  end

  @doc """
  Creates a changeset for marking a message as read by a user.
  """
  def mark_as_read_changeset(message_id, user_id) do
    %__MODULE__{}
    |> changeset(%{
      message_id: message_id,
      user_id: user_id,
      read_at: DateTime.utc_now()
    })
  end
end
