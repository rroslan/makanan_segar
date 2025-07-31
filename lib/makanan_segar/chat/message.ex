defmodule MakananSegar.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  alias MakananSegar.Products.Product
  alias MakananSegar.Accounts.User

  schema "chat_messages" do
    field :content, :string
    field :sender_name, :string
    field :sender_email, :string
    field :is_vendor_reply, :boolean, default: false

    belongs_to :product, Product
    belongs_to :user, User
    has_many :message_reads, MakananSegar.Chat.MessageRead

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :sender_name, :sender_email, :product_id, :user_id, :is_vendor_reply])
    |> validate_required([:content, :product_id])
    |> validate_length(:content, min: 1, max: 1000)
    |> validate_sender_info()
    |> foreign_key_constraint(:product_id)
    |> foreign_key_constraint(:user_id)
  end

  defp validate_sender_info(changeset) do
    user_id = get_field(changeset, :user_id)
    sender_name = get_field(changeset, :sender_name)
    is_vendor_reply = get_field(changeset, :is_vendor_reply)

    cond do
      # If user is logged in (including vendors), we don't need sender info
      user_id != nil ->
        changeset

      # If it's a vendor reply but no user_id, that's an error
      is_vendor_reply ->
        add_error(changeset, :user_id, "Vendor replies must have a user")

      # If anonymous customer message, just require name
      sender_name != nil and String.trim(sender_name) != "" ->
        changeset

      # Anonymous message without name
      true ->
        add_error(changeset, :sender_name, "Please provide your name")
    end
  end

  def display_sender_name(%__MODULE__{} = message) do
    cond do
      message.user && message.user.name ->
        message.user.name
      message.user && message.user.email ->
        message.user.email
      message.sender_name ->
        message.sender_name
      message.sender_email ->
        message.sender_email
      true ->
        "Anonymous"
    end
  end

  def is_from_vendor?(%__MODULE__{} = message) do
    message.is_vendor_reply
  end

  def is_from_customer?(%__MODULE__{} = message) do
    not message.is_vendor_reply
  end

  @doc """
  Checks if a message has been read by a specific user.
  """
  def read_by_user?(%__MODULE__{message_reads: %Ecto.Association.NotLoaded{}}, _user_id), do: false
  def read_by_user?(%__MODULE__{} = message, user_id) do
    Enum.any?(message.message_reads, fn read -> read.user_id == user_id end)
  end
end
