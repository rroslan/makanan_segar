defmodule MakananSegar.Chat.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  alias MakananSegar.Products.Product
  alias MakananSegar.Accounts.User

  @valid_statuses ~w(open resolved)

  schema "conversations" do
    field :status, :string, default: "open"
    field :resolved_at, :utc_datetime

    belongs_to :product, Product
    belongs_to :resolved_by_user, User, foreign_key: :resolved_by_user_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:status, :resolved_at, :product_id, :resolved_by_user_id])
    |> validate_required([:status, :product_id])
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_status_consistency()
    |> foreign_key_constraint(:product_id)
    |> foreign_key_constraint(:resolved_by_user_id)
    |> unique_constraint(:product_id)
  end

  @doc """
  Creates a changeset for marking a conversation as resolved.
  """
  def mark_resolved_changeset(conversation, user_id) do
    conversation
    |> changeset(%{
      status: "resolved",
      resolved_at: DateTime.utc_now(),
      resolved_by_user_id: user_id
    })
  end

  @doc """
  Creates a changeset for reopening a conversation.
  """
  def reopen_changeset(conversation) do
    conversation
    |> changeset(%{
      status: "open",
      resolved_at: nil,
      resolved_by_user_id: nil
    })
  end

  @doc """
  Returns the list of valid statuses.
  """
  def valid_statuses, do: @valid_statuses

  @doc """
  Checks if the conversation is resolved.
  """
  def resolved?(%__MODULE__{status: "resolved"}), do: true
  def resolved?(%__MODULE__{}), do: false

  @doc """
  Checks if the conversation is open.
  """
  def open?(%__MODULE__{status: "open"}), do: true
  def open?(%__MODULE__{}), do: false

  defp validate_status_consistency(changeset) do
    status = get_change(changeset, :status)
    _resolved_at = get_change(changeset, :resolved_at)
    _resolved_by_user_id = get_change(changeset, :resolved_by_user_id)

    case status do
      "resolved" ->
        changeset
        |> validate_required([:resolved_at, :resolved_by_user_id])

      "open" ->
        changeset
        |> validate_nil_field(:resolved_at, "must be nil when status is open")
        |> validate_nil_field(:resolved_by_user_id, "must be nil when status is open")

      _ ->
        changeset
    end
  end

  defp validate_nil_field(changeset, field, message) do
    case get_change(changeset, field) do
      nil -> changeset
      _ -> add_error(changeset, field, message)
    end
  end
end
