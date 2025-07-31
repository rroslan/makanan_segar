defmodule MakananSegar.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false
  alias MakananSegar.Repo

  alias MakananSegar.Chat.Message
  alias MakananSegar.Products

  @doc """
  Returns the list of messages for a specific product.

  ## Examples

      iex> list_product_messages(123)
      [%Message{}, ...]

  """
  def list_product_messages(product_id) do
    Message
    |> where([m], m.product_id == ^product_id)
    |> order_by([m], asc: m.inserted_at)
    |> preload([:user, :product])
    |> Repo.all()
  end

  @doc """
  Gets a single message.

  Raises `Ecto.NoResultsError` if the Message does not exist.

  ## Examples

      iex> get_message!(123)
      %Message{}

      iex> get_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_message!(id), do: Repo.get!(Message, id) |> Repo.preload([:user, :product])

  @doc """
  Creates a message.

  ## Examples

      iex> create_message(%{field: value})
      {:ok, %Message{}}

      iex> create_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_message(attrs \\ %{}) do
    IO.puts("DEBUG: Creating message with attrs: #{inspect(attrs)}")
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, message} ->
        IO.puts("DEBUG: Message inserted successfully: #{inspect(message)}")
        message = Repo.preload(message, [:user, :product])
        IO.puts("DEBUG: Message preloaded: #{inspect(message)}")
        broadcast_result = broadcast_message({:message_created, message})
        IO.puts("DEBUG: Broadcast result: #{inspect(broadcast_result)}")
        {:ok, message}
      error ->
        IO.puts("DEBUG: Message creation failed: #{inspect(error)}")
        error
    end
  end

  @doc """
  Creates a customer message (from a buyer/visitor).
  """
  def create_customer_message(product_id, attrs \\ %{}) do
    attrs =
      attrs
      |> Map.put("product_id", product_id)
      |> Map.put("is_vendor_reply", false)

    create_message(attrs)
  end

  @doc """
  Creates a vendor reply message.
  """
  def create_vendor_reply(product_id, vendor_user_id, content) do
    # Verify the vendor owns this product
    case Products.get_product_by_vendor(product_id, vendor_user_id) do
      nil ->
        {:error, :unauthorized}

      _product ->
        attrs = %{
          "product_id" => product_id,
          "user_id" => vendor_user_id,
          "content" => content,
          "is_vendor_reply" => true
        }
        IO.puts("DEBUG: Creating vendor reply with attrs: #{inspect(attrs)}")
        create_message(attrs)
    end
  end

  @doc """
  Updates a message.

  ## Examples

      iex> update_message(message, %{field: new_value})
      {:ok, %Message{}}

      iex> update_message(message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a message.

  ## Examples

      iex> delete_message(message)
      {:ok, %Message{}}

      iex> delete_message(message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.

  ## Examples

      iex> change_message(message)
      %Ecto.Changeset{data: %Message{}}

  """
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  @doc """
  Subscribe to real-time chat updates for a specific product.
  """
  def subscribe_to_product_chat(product_id) do
    Phoenix.PubSub.subscribe(MakananSegar.PubSub, "product_chat:#{product_id}")
  end

  @doc """
  Unsubscribe from real-time chat updates for a specific product.
  """
  def unsubscribe_from_product_chat(product_id) do
    Phoenix.PubSub.unsubscribe(MakananSegar.PubSub, "product_chat:#{product_id}")
  end

  @doc """
  Returns all chat messages for products owned by a specific vendor.
  Groups messages by product for easier dashboard display.
  """
  def get_vendor_chats(vendor_user_id) do
    query = from m in Message,
      join: p in assoc(m, :product),
      where: p.user_id == ^vendor_user_id,
      order_by: [desc: m.inserted_at],
      preload: [:user, product: [:user]]

    Repo.all(query)
    |> Enum.group_by(& &1.product_id)
  end

  @doc """
  Returns recent chat activity for vendor dashboard.
  Shows latest message from each conversation.
  """
  def get_vendor_chat_summary(vendor_user_id, limit \\ 5) do
    subquery = from m in Message,
      join: p in assoc(m, :product),
      where: p.user_id == ^vendor_user_id,
      group_by: m.product_id,
      select: %{product_id: m.product_id, max_inserted_at: max(m.inserted_at)}

    from(m in Message,
      join: s in subquery(subquery), on: m.product_id == s.product_id and m.inserted_at == s.max_inserted_at,
      order_by: [desc: m.inserted_at],
      limit: ^limit,
      preload: [:user, product: [:user]]
    )
    |> Repo.all()
  end

  @doc """
  Returns the count of unread messages for a vendor.
  For simplicity, we consider all customer messages as "unread" since we don't track read status.
  """
  def get_vendor_unread_count(vendor_user_id) do
    from(m in Message,
      join: p in assoc(m, :product),
      where: p.user_id == ^vendor_user_id and m.is_vendor_reply == false,
      select: count()
    )
    |> Repo.one()
  end

  @doc """
  Returns unread message counts per product for a vendor.
  Returns a map where keys are product_ids and values are unread counts.
  """
  def get_vendor_unread_counts_by_product(vendor_user_id) do
    from(m in Message,
      join: p in assoc(m, :product),
      where: p.user_id == ^vendor_user_id and m.is_vendor_reply == false,
      group_by: m.product_id,
      select: {m.product_id, count()}
    )
    |> Repo.all()
    |> Enum.into(%{})
  end

  @doc """
  Subscribe to all vendor chat updates.
  """
  def subscribe_to_vendor_chats(vendor_user_id) do
    Phoenix.PubSub.subscribe(MakananSegar.PubSub, "vendor_chats:#{vendor_user_id}")
  end

  # Private function to broadcast chat messages
  defp broadcast_message({:message_created, message}) do
    IO.puts("DEBUG: Broadcasting message for product #{message.product_id}")

    # Broadcast to product-specific channel
    broadcast_result1 = Phoenix.PubSub.broadcast(
      MakananSegar.PubSub,
      "product_chat:#{message.product_id}",
      {:message_created, message}
    )
    IO.puts("DEBUG: Product chat broadcast result: #{inspect(broadcast_result1)}")

    # If it's a customer message, also broadcast to vendor
    if not message.is_vendor_reply do
      message_with_product = Repo.preload(message, [:product])
      IO.puts("DEBUG: Broadcasting to vendor #{message_with_product.product.user_id}")
      broadcast_result2 = Phoenix.PubSub.broadcast(
        MakananSegar.PubSub,
        "vendor_chats:#{message_with_product.product.user_id}",
        {:new_customer_message, message}
      )
      IO.puts("DEBUG: Vendor chat broadcast result: #{inspect(broadcast_result2)}")
    end

    {:message_created, message}
  end

  defp broadcast_message(error), do: error
end
