defmodule MakananSegarWeb.ProductChatComponent do
  use MakananSegarWeb, :live_component

  import Phoenix.Naming, only: [humanize: 1]

  alias MakananSegar.Chat
  alias MakananSegar.Chat.Message

  @impl true
  def render(assigns) do
    IO.puts("DEBUG: Chat render assigns: #{inspect(Map.keys(assigns))}")
    IO.puts("DEBUG: Has form? #{Map.has_key?(assigns, :form)}")
    IO.puts("DEBUG: Has messages? #{Map.has_key?(assigns, :messages)}")
    IO.puts("DEBUG: Has product? #{Map.has_key?(assigns, :product)}")
    IO.puts("DEBUG: Has current_user? #{Map.has_key?(assigns, :current_user)}")

    ~H"""
    <div class="flex flex-col h-full">
      <%= if assigns[:product] do %>
        <!-- Chat Header -->
        <div class="border-b p-3">
          <h4 class="font-semibold text-gray-800">Ask about this product</h4>
          <p class="text-sm text-gray-600">Chat with the vendor</p>
        </div>

    <!-- Messages Container -->
        <div
          id={"chat-messages-#{@product.id}"}
          class="flex-1 overflow-y-auto p-4 space-y-3 min-h-[300px] max-h-[400px]"
          phx-hook="ScrollToBottom"
        >
          <%= if is_nil(@messages) or @messages == [] do %>
            <div class="text-center text-gray-500 mt-8">
              <div class="text-4xl mb-2">💬</div>
              <p>Start a conversation!</p>
              <p class="text-sm">Ask questions about this product</p>
            </div>
          <% else %>
            <%= for message <- (@messages || []) do %>
              <div class={[
                "flex",
                if(Message.is_from_vendor?(message), do: "justify-end", else: "justify-start")
              ]}>
                <div class={[
                  "max-w-xs lg:max-w-md px-4 py-2 rounded-lg",
                  if(Message.is_from_vendor?(message),
                    do: "bg-green-500 text-white",
                    else: "bg-gray-200 text-gray-800"
                  )
                ]}>
                  <div class="text-sm">
                    {message.content}
                  </div>
                  <div class={[
                    "text-xs mt-1 opacity-75",
                    if(Message.is_from_vendor?(message), do: "text-green-100", else: "text-gray-600")
                  ]}>
                    <span class="font-medium">{Message.display_sender_name(message)}</span>
                    <%= if Message.is_from_vendor?(message) do %>
                      <span class="ml-1">• Vendor</span>
                    <% end %>
                    <span class="ml-2">{format_message_time(message.inserted_at)}</span>
                  </div>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>

    <!-- Message Input Form -->
        <div class="border-t p-4">
          <%= if assigns[:form] && @form.source do %>
            <.form for={@form} phx-submit="send_message" phx-target={@myself} class="space-y-3">
              <%= if assigns[:current_user] && @current_user.id == @product.user_id do %>
                <!-- Vendor form - simple message only -->
                <div class="flex gap-2">
                  <.input
                    field={@form[:content]}
                    type="textarea"
                    placeholder="Reply to customer..."
                    rows="2"
                    class="flex-1 resize-none"
                    required
                  />
                  <button type="submit" class="btn btn-success self-end">
                    Send
                  </button>
                </div>
              <% else %>
                <!-- Customer form - name + message -->
                <div class="space-y-3">
                  <%= if not assigns[:current_user] do %>
                    <.input
                      field={@form[:sender_name]}
                      type="text"
                      placeholder="Your name"
                      class="text-sm"
                      required
                    />
                  <% end %>
                  <div class="flex gap-2">
                    <.input
                      field={@form[:content]}
                      type="textarea"
                      placeholder="Ask about this product..."
                      rows="2"
                      class="flex-1 resize-none"
                      required
                    />
                    <button type="submit" class="btn btn-primary self-end">
                      Send
                    </button>
                  </div>
                </div>
              <% end %>
            </.form>

    <!-- Error Messages -->
            <%= if @form.errors != [] do %>
              <div class="mt-2 text-sm text-red-600">
                <%= for {field, {message, _}} <- @form.errors do %>
                  <p>{humanize(field)}: {message}</p>
                <% end %>
              </div>
            <% end %>
          <% else %>
            <form phx-submit="send_message" phx-target={@myself} class="space-y-3">
              <%= if assigns[:current_user] && @current_user.id == @product.user_id do %>
                <!-- Vendor form - simple message only -->
                <div class="flex gap-2">
                  <textarea
                    name="message[content]"
                    placeholder="Reply to customer..."
                    rows="2"
                    class="textarea textarea-bordered flex-1 resize-none"
                    required
                  ></textarea>
                  <button type="submit" class="btn btn-success self-end">
                    Send
                  </button>
                </div>
              <% else %>
                <!-- Customer form - name + message -->
                <div class="space-y-3">
                  <%= if not assigns[:current_user] do %>
                    <input
                      type="text"
                      name="message[sender_name]"
                      placeholder="Your name"
                      class="input input-bordered text-sm"
                      required
                    />
                  <% end %>
                  <div class="flex gap-2">
                    <textarea
                      name="message[content]"
                      placeholder="Ask about this product..."
                      rows="2"
                      class="textarea textarea-bordered flex-1 resize-none"
                      required
                    ></textarea>
                    <button type="submit" class="btn btn-primary self-end">
                      Send
                    </button>
                  </div>
                </div>
              <% end %>
            </form>
          <% end %>
        </div>
      <% else %>
        <div class="flex-1 flex items-center justify-center">
          <div class="text-center text-gray-500">
            <p>Loading product information...</p>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    initial_data = %{
      "content" => "",
      "sender_name" => "",
      "sender_email" => "",
      "is_vendor_reply" => false
    }
    {:ok,
     socket
     |> assign(:messages, [])
     |> assign(:form, to_form(Message.changeset(%Message{}, initial_data)))}
  end

  @impl true
  def update(%{new_message: message} = _assigns, socket) do
    IO.puts("DEBUG: Chat component received new message: #{inspect(message)}")
    # Handle new message update from parent LiveView
    messages = socket.assigns.messages ++ [message]
    {:ok, assign(socket, :messages, messages)}
  end

  def update(%{product: product, current_user: current_user} = assigns, socket)
      when not is_nil(product) do
    IO.puts("DEBUG: Chat component updating for product #{product.id}")
    IO.puts("DEBUG: Current user: #{inspect(current_user)}")
    IO.puts("DEBUG: All assigns keys: #{inspect(Map.keys(assigns))}")

    # Subscribe to real-time chat updates for this product
    if connected?(socket) do
      IO.puts("DEBUG: Chat component subscribing to product_chat:#{product.id}")
      Chat.subscribe_to_product_chat(product.id)
    end

    # Load existing messages with safety
    messages =
      try do
        Chat.list_product_messages(product.id)
      rescue
        error ->
          IO.puts("DEBUG: Error loading messages: #{inspect(error)}")
          []
      end

    IO.puts("DEBUG: Loaded #{length(messages)} existing messages")

    # Create form changeset with proper initial data
    initial_data = %{
      "product_id" => product.id,
      "content" => "",
      "sender_name" => "",
      "sender_email" => "",
      "is_vendor_reply" => false
    }
    changeset = Message.changeset(%Message{}, initial_data)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:messages, messages || [])
     |> assign(:form, to_form(changeset))}
  end

  def update(assigns, socket) do
    IO.puts("DEBUG: Chat component update with incomplete assigns: #{inspect(Map.keys(assigns))}")
    # Handle cases where product or current_user might be missing

    # Ensure we have a form even if other assigns are missing
    form =
      if Map.has_key?(socket.assigns, :form) do
        socket.assigns.form
      else
        initial_data = %{
          "content" => "",
          "sender_name" => "",
          "sender_email" => "",
          "is_vendor_reply" => false
        }
        to_form(Message.changeset(%Message{}, initial_data))
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:messages, Map.get(socket.assigns, :messages, []))
     |> assign(:form, form)}
  end

  @impl true
  def handle_event("send_message", %{"message" => message_params}, socket) do
    %{product: product, current_user: current_user} = socket.assigns

    # Prepare message attributes
    attrs =
      if current_user do
        message_params
        |> Map.put("user_id", current_user.id)
        |> Map.put("is_vendor_reply", current_user.id == product.user_id)
      else
        message_params
        |> Map.put("is_vendor_reply", false)
      end

    IO.puts("DEBUG: Attempting to create message with attrs: #{inspect(attrs)}")

    # Use appropriate function based on whether it's a vendor reply
    result =
      if current_user && current_user.id == product.user_id do
        Chat.create_vendor_reply(product.id, current_user.id, message_params["content"])
      else
        Chat.create_customer_message(product.id, attrs)
      end

    case result do
      {:ok, message} ->
        IO.puts("DEBUG: Message created successfully: #{inspect(message)}")
        # Reset form
        changeset = Message.changeset(%Message{}, %{})
        {:noreply, assign(socket, :form, to_form(changeset))}

      {:error, changeset} ->
        IO.puts("DEBUG: Message creation failed: #{inspect(changeset.errors)}")
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  # Helper function to format message time
  defp format_message_time(datetime) do
    now = DateTime.now!("Asia/Kuala_Lumpur")
    diff_seconds = DateTime.diff(now, datetime, :second)

    cond do
      diff_seconds < 60 ->
        "just now"

      diff_seconds < 3600 ->
        minutes = div(diff_seconds, 60)
        "#{minutes}m ago"

      diff_seconds < 86400 ->
        hours = div(diff_seconds, 3600)
        "#{hours}h ago"

      true ->
        Calendar.strftime(datetime, "%b %d")
    end
  end
end
