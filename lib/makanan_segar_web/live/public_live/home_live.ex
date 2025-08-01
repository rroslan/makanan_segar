defmodule MakananSegarWeb.PublicLive.HomeLive do
  use MakananSegarWeb, :live_view

  alias MakananSegar.Products
  alias MakananSegar.Products.Product
  alias MakananSegarWeb.ProductChatComponent

  @impl true
  def render(assigns) do
    ~H"""
    <!-- Product Detail Modal -->
    <%= if @selected_product do %>
      <div
        class="modal modal-open"
        id="product-modal"
        phx-hook="DebugModal"
        data-selected-product="true"
      >
        <div class="modal-box w-11/12 max-w-5xl h-5/6 max-h-screen overflow-hidden flex flex-col">
          <!-- Modal Header -->
          <div class="flex justify-between items-center mb-4">
            <h2 class="text-2xl font-bold">{@selected_product.name}</h2>
            <button
              type="button"
              class="btn btn-sm btn-circle btn-ghost"
              phx-click="close_modal"
              phx-value-debug="close-button"
            >
              ✕
            </button>
          </div>
          
    <!-- Modal Content -->
          <%= if @modal_loading do %>
            <div class="flex-1 flex items-center justify-center">
              <div class="text-center">
                <span class="loading loading-spinner loading-lg"></span>
                <p class="mt-4">Loading product details...</p>
              </div>
            </div>
          <% else %>
            <div class="flex-1 overflow-y-auto">
              <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <!-- Product Details -->
                <div class="space-y-4">
                  <!-- Product Image -->
                  <div class="aspect-square bg-gray-100 rounded-lg overflow-hidden">
                    <%= if @selected_product.image do %>
                      <img
                        src={@selected_product.image}
                        alt={@selected_product.name}
                        class="w-full h-full object-cover"
                      />
                    <% else %>
                      <div class="w-full h-full flex items-center justify-center text-gray-400">
                        <div class="text-6xl">
                          <%= case @selected_product.category do %>
                            <% "fish" -> %>
                              🐟
                            <% "vegetables" -> %>
                              🥬
                            <% "fruits" -> %>
                              🥭
                            <% _ -> %>
                              📦
                          <% end %>
                        </div>
                      </div>
                    <% end %>
                  </div>
                  
    <!-- Product Info -->
                  <div class="space-y-3">
                    <div class="text-3xl font-bold text-green-600">
                      RM {@selected_product.price}
                    </div>
                    <p class="text-gray-700">{@selected_product.description}</p>
                    <div class="grid grid-cols-2 gap-4 text-sm">
                      <div>
                        <span class="font-medium">Category:</span>
                        <span class="ml-2">
                          {Product.category_display_name(@selected_product.category)}
                        </span>
                      </div>
                      <div>
                        <span class="font-medium">Vendor:</span>
                        <span class="ml-2">{@selected_product.user.name}</span>
                      </div>
                    </div>
                  </div>
                </div>
                
    <!-- Chat Section -->
                <div class="space-y-4 h-full flex flex-col">
                  <%= if @chat_loading do %>
                    <div class="flex items-center justify-center h-full">
                      <div class="text-center">
                        <span class="loading loading-spinner loading-md"></span>
                        <p class="mt-2 text-sm">Loading chat...</p>
                      </div>
                    </div>
                  <% else %>
                    <div class="flex flex-col h-full">
                      <!-- Chat Header -->
                      <div class="border-b p-3">
                        <%= if assigns[:current_user] && @current_user.is_vendor && @selected_product.user_id == @current_user.id do %>
                          <!-- Vendor View -->
                          <div class="flex justify-between items-start">
                            <div>
                              <h4 class="font-semibold text-gray-800">Customer Messages</h4>
                              <p class="text-sm text-gray-600">Manage customer inquiries</p>
                            </div>
                            <div class="flex gap-2">
                              <%= if assigns[:conversation_status] && @conversation_status == "resolved" do %>
                                <button
                                  phx-click="reopen_conversation"
                                  phx-value-product-id={@selected_product.id}
                                  class="btn btn-sm btn-outline btn-warning"
                                >
                                  <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                                    <path d="M4 2a1 1 0 011 1v2.101a7.002 7.002 0 0111.601 2.566 1 1 0 11-1.885.666A5.002 5.002 0 005.999 7H9a1 1 0 010 2H4a1 1 0 01-1-1V3a1 1 0 011-1z">
                                    </path>
                                    <path d="M5.707 12.707a1 1 0 010-1.414l1.414-1.414a1 1 0 011.414 1.414L7.414 12.5H9a1 1 0 010 2H4a1 1 0 01-1-1v-2a1 1 0 011-1h2.293l-1.086-1.086z">
                                    </path>
                                  </svg>
                                  Reopen
                                </button>
                                <div class="badge badge-success">Resolved</div>
                              <% else %>
                                <button
                                  phx-click="mark_conversation_resolved"
                                  phx-value-product-id={@selected_product.id}
                                  class="btn btn-sm btn-success"
                                >
                                  <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                                    <path
                                      fill-rule="evenodd"
                                      d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                                      clip-rule="evenodd"
                                    >
                                    </path>
                                  </svg>
                                  Mark Resolved
                                </button>
                                <div class="badge badge-info">Open</div>
                              <% end %>
                            </div>
                          </div>
                        <% else %>
                          <!-- Customer View -->
                          <h4 class="font-semibold text-gray-800">Ask about this product</h4>
                          <p class="text-sm text-gray-600">Chat with the vendor</p>
                        <% end %>
                      </div>
                      
    <!-- Messages Container -->
                      <div
                        class="flex-1 overflow-y-auto p-4 space-y-3 min-h-[300px] max-h-[400px]"
                        id={"chat-messages-#{@selected_product.id}"}
                        phx-hook="ScrollToBottom"
                      >
                        <%= if assigns[:chat_messages] && is_list(@chat_messages) && length(@chat_messages) > 0 do %>
                          <%= for message <- @chat_messages do %>
                            <div class={[
                              "flex",
                              if(message.is_vendor_reply, do: "justify-end", else: "justify-start")
                            ]}>
                              <div class={[
                                "max-w-xs lg:max-w-md px-4 py-2 rounded-lg",
                                if(message.is_vendor_reply,
                                  do: "bg-green-500 text-white",
                                  else: "bg-gray-200 text-gray-800"
                                )
                              ]}>
                                <div class="text-sm">
                                  {message.content}
                                </div>
                                <div class={[
                                  "text-xs mt-1 opacity-75",
                                  if(message.is_vendor_reply,
                                    do: "text-green-100",
                                    else: "text-gray-600"
                                  )
                                ]}>
                                  <span class="font-medium">
                                    <%= if message.user do %>
                                      {message.user.name || message.user.email}
                                    <% else %>
                                      {message.sender_name || "Anonymous"}
                                    <% end %>
                                  </span>
                                  <%= if message.is_vendor_reply do %>
                                    <span class="ml-1">• Vendor</span>
                                  <% end %>
                                  <span class="ml-2">{format_message_time(message.inserted_at)}</span>
                                </div>
                              </div>
                            </div>
                          <% end %>
                        <% else %>
                          <div class="text-center text-gray-500 mt-8">
                            <div class="text-4xl mb-2">💬</div>
                            <p>Start a conversation!</p>
                            <p class="text-sm">Ask questions about this product</p>
                          </div>
                        <% end %>
                      </div>
                      
    <!-- Simple Message Form -->
                      <div class="border-t p-4">
                        <form
                          phx-submit="send_chat_message"
                          phx-change="validate_chat_message"
                          class="space-y-3"
                          id="chat-form"
                          phx-hook="ChatFormReset"
                        >
                          <input type="hidden" name="product_id" value={@selected_product.id} />
                          <div class="space-y-3">
                            <%= if is_nil(@current_user) and not Map.get(assigns, :guest_name_provided, false) do %>
                              <input
                                type="text"
                                name="sender_name"
                                placeholder="Your name"
                                class="input input-bordered text-sm"
                                id="sender-name-input"
                                required
                              />
                            <% end %>
                            <div class="flex gap-2">
                              <textarea
                                name="content"
                                placeholder="Ask about this product..."
                                rows="2"
                                class="textarea textarea-bordered flex-1 resize-none"
                                id="message-content-input"
                                required
                              ></textarea>
                              <button type="submit" class="btn btn-primary self-end" id="send-button">
                                <span
                                  class="loading loading-spinner loading-sm hidden"
                                  id="loading-spinner"
                                >
                                </span>
                                <span id="button-text">Send</span>
                              </button>
                            </div>
                          </div>
                        </form>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>
        </div>
        <div class="modal-backdrop" phx-click="close_modal" phx-value-debug="backdrop"></div>
      </div>
    <% end %>

    <!-- Vendor Detail Modal -->
    <%= if @selected_vendor do %>
      <div class="modal modal-open">
        <div class="modal-box w-11/12 max-w-4xl max-h-[90vh] overflow-y-auto">
          <!-- Modal Header -->
          <div class="flex justify-between items-center mb-6">
            <h2 class="text-2xl font-bold">Vendor Profile</h2>
            <button type="button" class="btn btn-sm btn-circle btn-ghost" phx-click="close_modal">
              ✕
            </button>
          </div>
          
    <!-- Vendor Content -->
          <div class="space-y-6">
            <!-- Vendor Header -->
            <div class="bg-gradient-to-r from-primary/10 to-secondary/10 p-6 rounded-lg">
              <div class="flex items-start gap-6">
                <div class="avatar">
                  <div class="w-24 h-24 rounded-full ring ring-primary ring-offset-2">
                    <%= if @selected_vendor.profile_image do %>
                      <img
                        src={@selected_vendor.profile_image}
                        alt={@selected_vendor.name || "Vendor"}
                        class="object-cover"
                      />
                    <% else %>
                      <div class="bg-primary text-primary-content w-full h-full flex items-center justify-center text-3xl font-bold">
                        {String.first(@selected_vendor.name || @selected_vendor.email)
                        |> String.upcase()}
                      </div>
                    <% end %>
                  </div>
                </div>
                <div class="flex-1">
                  <h3 class="text-3xl font-bold text-primary mb-2">
                    {@selected_vendor.business_name || @selected_vendor.name || "Local Vendor"}
                  </h3>
                  <%= if @selected_vendor.business_name && @selected_vendor.name do %>
                    <p class="text-xl text-gray-700 mb-1">Owner: {@selected_vendor.name}</p>
                  <% end %>
                  <p class="text-gray-600 mb-3">{@selected_vendor.email}</p>
                  
    <!-- Business Type Badge -->
                  <%= if @selected_vendor.business_type do %>
                    <div class="flex gap-2 mb-3">
                      <span class="badge badge-primary badge-lg">
                        {String.capitalize(@selected_vendor.business_type)} Vendor
                      </span>
                    </div>
                  <% end %>
                  
    <!-- Business Description -->
                  <%= if @selected_vendor.business_description do %>
                    <div class="bg-white/70 p-4 rounded-lg">
                      <p class="text-gray-700 leading-relaxed">
                        {@selected_vendor.business_description}
                      </p>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
            
    <!-- Contact & Business Details -->
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <!-- Contact Information -->
              <div class="card bg-base-100 shadow-lg">
                <div class="card-body">
                  <h4 class="card-title text-xl flex items-center gap-2">
                    <span class="text-2xl">📞</span> Contact Information
                  </h4>
                  <div class="space-y-4">
                    <%= if @selected_vendor.phone do %>
                      <div class="flex items-center gap-3 p-3 bg-base-200 rounded-lg">
                        <span class="text-2xl">📱</span>
                        <div>
                          <span class="font-medium text-sm text-gray-600">Phone</span>
                          <p class="font-semibold">{@selected_vendor.phone}</p>
                        </div>
                      </div>
                    <% end %>

                    <%= if @selected_vendor.address do %>
                      <div class="flex items-start gap-3 p-3 bg-base-200 rounded-lg">
                        <span class="text-2xl">📍</span>
                        <div>
                          <span class="font-medium text-sm text-gray-600">Address</span>
                          <p class="font-semibold">{@selected_vendor.address}</p>
                        </div>
                      </div>
                    <% end %>

                    <%= if @selected_vendor.website do %>
                      <div class="flex items-center gap-3 p-3 bg-base-200 rounded-lg">
                        <span class="text-2xl">🌐</span>
                        <div>
                          <span class="font-medium text-sm text-gray-600">Website</span>
                          <a
                            href={@selected_vendor.website}
                            target="_blank"
                            class="font-semibold text-primary hover:underline block"
                          >
                            {String.replace(@selected_vendor.website, ~r/^https?:\/\//, "")}
                          </a>
                        </div>
                      </div>
                    <% end %>

                    <%= if !@selected_vendor.phone and !@selected_vendor.address and !@selected_vendor.website do %>
                      <div class="text-center py-6">
                        <span class="text-4xl">💬</span>
                        <p class="text-gray-500 mt-2">Contact via product messaging</p>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
              
    <!-- Business Hours & Info -->
              <div class="card bg-base-100 shadow-lg">
                <div class="card-body">
                  <h4 class="card-title text-xl flex items-center gap-2">
                    <span class="text-2xl">🏪</span> Business Details
                  </h4>
                  <div class="space-y-4">
                    <%= if @selected_vendor.business_hours do %>
                      <div class="flex items-center gap-3 p-3 bg-base-200 rounded-lg">
                        <span class="text-2xl">⏰</span>
                        <div>
                          <span class="font-medium text-sm text-gray-600">Operating Hours</span>
                          <p class="font-semibold">{@selected_vendor.business_hours}</p>
                        </div>
                      </div>
                    <% end %>

                    <%= if @selected_vendor.business_registration_number do %>
                      <div class="flex items-center gap-3 p-3 bg-base-200 rounded-lg">
                        <span class="text-2xl">📋</span>
                        <div>
                          <span class="font-medium text-sm text-gray-600">Registration</span>
                          <p class="font-semibold">{@selected_vendor.business_registration_number}</p>
                        </div>
                      </div>
                    <% end %>

                    <%= if !@selected_vendor.business_hours and !@selected_vendor.business_registration_number do %>
                      <div class="text-center py-6">
                        <span class="text-4xl">🌟</span>
                        <p class="text-gray-500 mt-2">Trusted local vendor</p>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="modal-backdrop" phx-click="close_modal"></div>
      </div>
    <% end %>

    <div class="min-h-screen bg-base-100">
      <!-- Navigation Bar -->
      <div class="navbar bg-base-100 shadow-md sticky top-0 z-50">
        <div class="navbar-start">
          <.link navigate={~p"/"} class="btn btn-ghost text-xl">
            <span class="text-2xl mr-2">🥬</span>
            <span class="hidden sm:inline">MakananSegar</span>
          </.link>
        </div>

        <div class="navbar-center hidden lg:flex">
          <!-- Navigation links removed - home page shows all products -->
        </div>

        <div class="navbar-end">
          <%= if assigns[:current_user] do %>
            <div class="flex items-center gap-2">
              <%= if assigns[:current_user] && @current_user.is_admin do %>
                <.link navigate={~p"/admin"} class="btn btn-primary btn-sm">
                  Admin Dashboard
                </.link>
              <% end %>
              <%= if assigns[:current_user] && @current_user.is_vendor do %>
                <.link navigate={~p"/vendor"} class="btn btn-success btn-sm">
                  Vendor Dashboard
                </.link>
              <% end %>
              
    <!-- User dropdown -->
              <div class="dropdown dropdown-end">
                <div tabindex="0" role="button" class="btn btn-ghost btn-circle avatar">
                  <div class="w-10 rounded-full">
                    <%= if assigns[:current_user] && @current_user.profile_image do %>
                      <img src={@current_user.profile_image} alt={@current_user.name || "User"} />
                    <% else %>
                      <div class="w-10 h-10 rounded-full bg-primary text-primary-content flex items-center justify-center">
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke-width="1.5"
                          stroke="currentColor"
                          class="w-6 h-6"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z"
                          />
                        </svg>
                      </div>
                    <% end %>
                  </div>
                </div>
                <ul
                  tabindex="0"
                  class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52"
                >
                  <li class="menu-title">
                    <span>
                      {if assigns[:current_user],
                        do: @current_user.name || @current_user.email,
                        else: "Guest"}
                    </span>
                  </li>
                  <li><.link navigate={~p"/users/settings"}>Settings</.link></li>
                  <li>
                    <.form for={%{}} action={~p"/users/log-out"} method="delete" class="w-full">
                      <button
                        type="submit"
                        class="w-full text-left px-4 py-2 hover:bg-base-200 rounded-lg transition-colors"
                        onclick="this.disabled=true; this.innerHTML='Logging out...'; this.form.submit();"
                      >
                        Log out
                      </button>
                    </.form>
                  </li>
                </ul>
              </div>
            </div>
          <% else %>
            <!-- User dropdown for non-authenticated users -->
            <div class="dropdown dropdown-end">
              <div tabindex="0" role="button" class="btn btn-ghost btn-circle">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  class="w-6 h-6"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z"
                  />
                </svg>
              </div>
              <ul
                tabindex="0"
                class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52"
              >
                <li><.link navigate={~p"/users/log-in"}>Log in</.link></li>
                <li><.link navigate={~p"/users/register"}>Register</.link></li>
                <li class="menu-title mt-2">
                  <span>For Vendors</span>
                </li>
                <li><.link navigate={~p"/users/register"}>Become a Vendor</.link></li>
              </ul>
            </div>
          <% end %>
        </div>
      </div>
      
    <!-- Products Grid -->
      <div class="container mx-auto px-4 py-8">
        <%= if @products == [] do %>
          <div class="text-center py-16">
            <div class="text-6xl mb-8">🛒</div>
            <h2 class="text-3xl font-bold mb-4">No products available</h2>
            <p class="text-base-content/70">Check back later for fresh products!</p>
          </div>
        <% else %>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            <%= for product <- @products do %>
              <div
                id={"product-#{product.id}"}
                class="card bg-base-100 shadow-xl hover:shadow-2xl transition-all duration-300 h-full relative"
              >
                <!-- Chat Button and Notification Badge for Vendors -->
                <%= if assigns[:current_user] && @current_user.is_vendor && product.user_id == @current_user.id do %>
                  <!-- Chat Button -->
                  <div class="absolute top-2 left-2 z-10">
                    <button
                      class="btn btn-sm btn-circle btn-info tooltip tooltip-right"
                      data-tip="View Customer Messages"
                      phx-click="view_product"
                      phx-value-id={product.id}
                    >
                      <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                        <path d="M2 5a2 2 0 012-2h7a2 2 0 012 2v4a2 2 0 01-2 2H9l-3 3v-3H4a2 2 0 01-2-2V5z">
                        </path>
                        <path d="M15 7v2a4 4 0 01-4 4H9.828l-1.766 1.767c.28.149.599.233.938.233h2l3 3v-3h2a2 2 0 002-2V9a2 2 0 00-2-2h-1z">
                        </path>
                      </svg>
                    </button>
                  </div>
                  
    <!-- Notification Badge -->
                  <%= if Map.get(@unread_counts, product.id, 0) > 0 do %>
                    <div class="absolute top-2 right-2 z-10">
                      <div class="badge badge-error badge-sm">
                        <svg class="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20">
                          <path d="M2.003 5.884L10 9.882l7.997-3.998A2 2 0 0016 4H4a2 2 0 00-1.997 1.884z">
                          </path>
                          <path d="M18 8.118l-8 4-8-4V14a2 2 0 002 2h12a2 2 0 002-2V8.118z"></path>
                        </svg>
                        {Map.get(@unread_counts, product.id)}
                      </div>
                    </div>
                  <% end %>
                <% end %>
                <!-- Product Image -->
                <div
                  id={"product-click-#{product.id}"}
                  class="cursor-pointer group"
                  phx-click="view_product"
                  phx-value-id={product.id}
                  phx-hook="ProductClickDebug"
                  onclick="console.log('Product button clicked:', this.dataset.phxValueId)"
                >
                  <figure class="px-4 pt-4">
                    <div class="w-full h-48 rounded-lg overflow-hidden bg-base-200">
                      <%= if product.image do %>
                        <img
                          src={product.image}
                          alt={product.name}
                          class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                        />
                      <% else %>
                        <div class="w-full h-full flex items-center justify-center text-6xl">
                          <%= case product.category do %>
                            <% "fish" -> %>
                              🐟
                            <% "vegetables" -> %>
                              🥬
                            <% "fruits" -> %>
                              🥭
                            <% _ -> %>
                              📦
                          <% end %>
                        </div>
                      <% end %>
                    </div>
                  </figure>
                </div>

                <div class="card-body p-4">
                  <!-- Category Badge -->
                  <div class={"badge badge-sm #{category_badge_class(product.category)} mb-2"}>
                    {Product.category_display_name(product.category)}
                  </div>
                  
    <!-- Product Name -->
                  <div
                    class="cursor-pointer hover:text-primary text-left w-full"
                    phx-click="view_product"
                    phx-value-id={product.id}
                    onclick="console.log('Product title clicked:', this.dataset.phxValueId)"
                  >
                    <h3 class="card-title text-lg line-clamp-1">{product.name}</h3>
                  </div>
                  
    <!-- Description -->
                  <p class="text-sm text-base-content/70 line-clamp-2 flex-grow">
                    {product.description || "Fresh product from local vendor"}
                  </p>
                  
    <!-- Price -->
                  <div class="text-2xl font-bold text-primary mt-2">
                    RM {product.price}
                  </div>
                  
    <!-- Expiry Info -->
                  <div class="text-xs text-base-content/60 mt-1">
                    <%= if Product.expired?(product) do %>
                      <span class="text-error">Expired</span>
                    <% else %>
                      Expires {format_time_until_expiry(product.expires_at)}
                    <% end %>
                  </div>
                  
    <!-- Vendor Info with Avatar -->
                  <%= if product.user do %>
                    <button
                      phx-click="view_vendor"
                      phx-value-id={product.user.id}
                      class="flex items-center gap-2 mt-3 text-xs text-base-content/60 hover:text-primary transition-colors w-full text-left"
                      type="button"
                    >
                      <div class="avatar">
                        <div class="w-6 h-6 rounded-full">
                          <%= if product.user.profile_image do %>
                            <img src={product.user.profile_image} alt={product.user.name || "Vendor"} />
                          <% else %>
                            <div class="bg-base-300 text-base-content w-full h-full flex items-center justify-center text-xs">
                              {String.first(product.user.name || product.user.email)
                              |> String.upcase()}
                            </div>
                          <% end %>
                        </div>
                      </div>
                      <div class="flex-1 min-w-0">
                        <p class="text-sm font-medium group-hover:text-primary transition-colors">
                          {product.user.business_name || product.user.name || "Local vendor"}
                        </p>
                      </div>
                      <.icon name="hero-arrow-right" class="w-3 h-3" />
                    </button>
                  <% end %>
                  
    <!-- Vendor Chat Management Section -->
                  <%= if assigns[:current_user] && @current_user.is_vendor && product.user_id == @current_user.id do %>
                    <div class="mt-3 pt-3 border-t border-base-300">
                      <button
                        phx-click="view_product"
                        phx-value-id={product.id}
                        class="btn btn-sm btn-outline btn-info w-full flex items-center gap-2"
                      >
                        <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                          <path d="M2 5a2 2 0 012-2h7a2 2 0 012 2v4a2 2 0 01-2 2H9l-3 3v-3H4a2 2 0 01-2-2V5z">
                          </path>
                          <path d="M15 7v2a4 4 0 01-4 4H9.828l-1.766 1.767c.28.149.599.233.938.233h2l3 3v-3h2a2 2 0 002-2V9a2 2 0 00-2-2h-1z">
                          </path>
                        </svg>
                        <span>Customer Messages</span>
                        <%= if Map.get(@unread_counts, product.id, 0) > 0 do %>
                          <div class="badge badge-error badge-xs">
                            {Map.get(@unread_counts, product.id)}
                          </div>
                        <% end %>
                        <%= if Map.get(@conversation_statuses, product.id) == "resolved" do %>
                          <div class="badge badge-success badge-xs ml-1">✓</div>
                        <% end %>
                      </button>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    # Get current user from session
    current_user =
      case session["user_token"] do
        nil ->
          IO.puts("DEBUG: No user token in session")
          nil

        token ->
          case MakananSegar.Accounts.get_user_by_session_token(token) do
            {user, _} ->
              IO.puts("DEBUG: User authenticated: #{user.email}")
              user

            _ ->
              IO.puts("DEBUG: Invalid user token")
              nil
          end
      end

    IO.puts("DEBUG: HomeLive mount - current_user: #{inspect(current_user)}")
    IO.puts("DEBUG: Socket connected?: #{connected?(socket)}")

    # All users can view the home page (no redirects)
    case current_user do
      _ ->
        # All users (admins, vendors, regular users, and non-authenticated) can view products
        try do
          if connected?(socket) do
            Phoenix.PubSub.subscribe(MakananSegar.PubSub, "products")

            # If user is a vendor, also subscribe to their chat notifications
            if current_user && current_user.is_vendor do
              MakananSegar.Chat.subscribe_to_vendor_chats(current_user.id)
            end
          end

          products = Products.list_public_products()

          # Load unread message counts for vendors (only open conversations)
          unread_counts =
            if current_user && current_user.is_vendor do
              try do
                all_counts =
                  MakananSegar.Chat.get_vendor_unread_counts_by_product_open_only(current_user.id)

                # Remove counts for products viewed in this session
                viewed_products = MapSet.new()

                Enum.reduce(viewed_products, all_counts, fn product_id, acc ->
                  Map.delete(acc, product_id)
                end)
              rescue
                _ -> %{}
              end
            else
              %{}
            end

          # Load conversation statuses for vendors
          conversation_statuses =
            if current_user && current_user.is_vendor do
              try do
                product_ids = Enum.map(products, & &1.id)
                MakananSegar.Chat.get_conversations_status(product_ids)
              rescue
                _ -> %{}
              end
            else
              %{}
            end

          {:ok,
           socket
           |> assign(:page_title, "Fresh Products - MakananSegar")
           |> assign(:products, products)
           |> assign(:selected_product, nil)
           |> assign(:selected_vendor, nil)
           |> assign(:unread_counts, unread_counts)
           |> assign(:conversation_statuses, conversation_statuses)
           |> assign(:modal_loading, false)
           |> assign(:chat_loading, false)
           |> assign(:current_user, current_user)
           |> assign(:guest_name_provided, false)
           |> assign(:chat_messages, [])
           |> assign(:viewed_products, MapSet.new())
           |> assign(:connection_stable, connected?(socket))}
        rescue
          error ->
            IO.puts("DEBUG: Error in mount: #{inspect(error)}")

            {:ok,
             socket
             |> assign(:page_title, "Fresh Products - MakananSegar")
             |> assign(:products, [])
             |> assign(:selected_product, nil)
             |> assign(:selected_vendor, nil)
             |> assign(:unread_counts, %{})
             |> assign(:conversation_statuses, %{})
             |> assign(:modal_loading, false)
             |> assign(:chat_loading, false)
             |> assign(:current_user, current_user)
             |> assign(:guest_name_provided, false)
             |> assign(:chat_messages, [])
             |> assign(:viewed_products, MapSet.new())
             |> assign(:connection_stable, false)
             |> put_flash(:error, "Error loading page. Please refresh.")}
        end
    end
  end

  @impl true
  def handle_event("view_product", %{"id" => product_id}, socket) do
    # Handle both connected and disconnected states gracefully
    socket = assign(socket, :connection_stable, connected?(socket))

    # Set loading states immediately
    socket = socket |> assign(:modal_loading, true) |> assign(:chat_loading, true)

    case Integer.parse(product_id) do
      {id, ""} ->
        try do
          product = Products.get_public_product!(id)

          # Subscribe to chat updates for this product
          if connected?(socket) do
            MakananSegar.Chat.subscribe_to_product_chat(product.id)
          end

          # Load existing messages for this product
          chat_messages =
            try do
              MakananSegar.Chat.list_product_messages(product.id)
            rescue
              _ -> []
            end

          # Load conversation status for vendors viewing their own products
          conversation_status =
            if socket.assigns.current_user &&
                 socket.assigns.current_user.is_vendor &&
                 product.user_id == socket.assigns.current_user.id do
              case MakananSegar.Chat.get_conversation_by_product(product.id) do
                nil -> "open"
                conversation -> conversation.status
              end
            else
              nil
            end

          # Clear notification count if vendor is viewing their own product
          unread_counts =
            if socket.assigns.current_user &&
                 socket.assigns.current_user.is_vendor &&
                 product.user_id == socket.assigns.current_user.id do
              # Remove the count for this product since vendor is now viewing it
              Map.delete(socket.assigns.unread_counts || %{}, product.id)
            else
              socket.assigns.unread_counts || %{}
            end

          # Mark product as viewed by vendor (for this session)
          viewed_products = Map.get(socket.assigns, :viewed_products, MapSet.new())

          viewed_products =
            if socket.assigns.current_user &&
                 socket.assigns.current_user.is_vendor &&
                 product.user_id == socket.assigns.current_user.id do
              MapSet.put(viewed_products, product.id)
            else
              viewed_products
            end

          # Set product and clear loading states
          socket =
            socket
            |> assign(:selected_product, product)
            |> assign(:modal_loading, false)
            |> assign(:chat_loading, false)
            |> assign(:guest_name_provided, false)
            |> assign(:chat_messages, chat_messages)
            |> assign(:conversation_status, conversation_status)
            |> assign(:unread_counts, unread_counts)
            |> assign(:viewed_products, viewed_products)

          {:noreply, socket}
        rescue
          _error ->
            {:noreply,
             socket
             |> assign(:modal_loading, false)
             |> assign(:chat_loading, false)
             |> put_flash(:error, "Failed to load product")}
        end

      _ ->
        {:noreply, socket |> assign(:modal_loading, false) |> assign(:chat_loading, false)}
    end
  end

  @impl true
  def handle_event("test_connection", _params, socket) do
    {:noreply, put_flash(socket, :info, "LiveView connection test successful!")}
  end

  @impl true
  def handle_event("force_modal_test", %{"id" => product_id}, socket) do
    # Force set selected_product to test modal display
    try do
      product = Products.get_public_product!(String.to_integer(product_id))

      socket =
        socket
        |> assign(:selected_product, product)
        |> assign(:modal_loading, false)
        |> assign(:chat_loading, false)
        |> put_flash(:info, "Force modal test - modal should be visible now!")

      {:noreply, socket}
    rescue
      _error ->
        {:noreply, put_flash(socket, :error, "Force modal test failed")}
    end
  end

  @impl true
  def handle_event("send_chat_message", params, socket) do
    case socket.assigns.selected_product do
      nil ->
        {:noreply, put_flash(socket, :error, "Please select a product first")}

      product ->
        # Prepare message attributes
        message_attrs = %{
          "content" => params["content"],
          "product_id" => product.id,
          "sender_name" => params["sender_name"],
          "is_vendor_reply" => false
        }

        # Add user_id if user is logged in
        message_attrs =
          if socket.assigns.current_user do
            Map.put(message_attrs, "user_id", socket.assigns.current_user.id)
          else
            message_attrs
          end

        try do
          case MakananSegar.Chat.create_customer_message(product.id, message_attrs) do
            {:ok, message} ->
              # Reload messages to include the new one
              updated_messages =
                try do
                  MakananSegar.Chat.list_product_messages(product.id)
                rescue
                  _ -> socket.assigns.chat_messages ++ [message]
                end

              # Reset form and show success
              socket =
                socket
                |> put_flash(:info, "Message sent successfully!")
                |> assign(:guest_name_provided, not is_nil(params["sender_name"]))
                |> assign(:chat_messages, updated_messages)
                |> push_event("reset_chat_form", %{})

              {:noreply, socket}

            {:error, _changeset} ->
              {:noreply, put_flash(socket, :error, "Failed to send message. Please try again.")}
          end
        rescue
          _error ->
            {:noreply, put_flash(socket, :error, "An error occurred while sending your message.")}
        end
    end
  end

  @impl true
  def handle_event("validate_chat_message", _params, socket) do
    # Just acknowledge the validation - we're keeping it simple
    {:noreply, socket}
  end

  @impl true
  def handle_event("mark_conversation_resolved", %{"product-id" => product_id}, socket) do
    if socket.assigns.current_user && socket.assigns.current_user.is_vendor do
      case MakananSegar.Chat.mark_conversation_resolved(
             String.to_integer(product_id),
             socket.assigns.current_user.id
           ) do
        {:ok, _conversation} ->
          # Update conversation status and refresh notification counts
          unread_counts =
            MakananSegar.Chat.get_vendor_unread_counts_by_product_open_only(
              socket.assigns.current_user.id
            )

          socket =
            socket
            |> assign(:conversation_status, "resolved")
            |> assign(:unread_counts, unread_counts)
            |> put_flash(:info, "Conversation marked as resolved")

          {:noreply, socket}

        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "Failed to mark conversation as resolved")}
      end
    else
      {:noreply, put_flash(socket, :error, "Unauthorized")}
    end
  end

  def handle_event("reopen_conversation", %{"product-id" => product_id}, socket) do
    if socket.assigns.current_user && socket.assigns.current_user.is_vendor do
      case MakananSegar.Chat.reopen_conversation(
             String.to_integer(product_id),
             socket.assigns.current_user.id
           ) do
        {:ok, _conversation} ->
          # Update conversation status and refresh notification counts
          unread_counts =
            MakananSegar.Chat.get_vendor_unread_counts_by_product_open_only(
              socket.assigns.current_user.id
            )

          socket =
            socket
            |> assign(:conversation_status, "open")
            |> assign(:unread_counts, unread_counts)
            |> put_flash(:info, "Conversation reopened")

          {:noreply, socket}

        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "Failed to reopen conversation")}
      end
    else
      {:noreply, put_flash(socket, :error, "Unauthorized")}
    end
  end

  def handle_event("close_modal", _params, socket) do
    # Unsubscribe from chat updates if we were subscribed
    if socket.assigns.selected_product do
      MakananSegar.Chat.unsubscribe_from_product_chat(socket.assigns.selected_product.id)
    end

    {:noreply,
     socket
     |> assign(:selected_product, nil)
     |> assign(:selected_vendor, nil)
     |> assign(:modal_loading, false)
     |> assign(:guest_name_provided, false)
     |> assign(:chat_messages, [])
     |> assign(:chat_loading, false)}
  end

  @impl true
  def handle_event("view_vendor", %{"id" => vendor_id}, socket) do
    try do
      vendor_id_int = String.to_integer(vendor_id)
      vendor = MakananSegar.Accounts.get_user!(vendor_id_int)

      {:noreply,
       socket
       |> assign(:selected_vendor, vendor)}
    rescue
      _error ->
        {:noreply, put_flash(socket, :error, "Could not load vendor details")}
    end
  end

  @impl true
  def handle_event(event_name, params, socket) do
    IO.puts("=== UNHANDLED EVENT ===")
    IO.puts("DEBUG: Unhandled event: #{event_name} with params: #{inspect(params)}")
    IO.puts("DEBUG: Current user: #{inspect(socket.assigns.current_user)}")
    IO.puts("DEBUG: Socket connected?: #{connected?(socket)}")
    {:noreply, socket}
  end

  @impl true
  def handle_info({:product_updated, _product}, socket) do
    {:noreply, assign(socket, :products, Products.list_public_products())}
  end

  def handle_info({:product_created, _product}, socket) do
    {:noreply, assign(socket, :products, Products.list_public_products())}
  end

  def handle_info({:product_deleted, _product_id}, socket) do
    {:noreply, assign(socket, :products, Products.list_public_products())}
  end

  def handle_info({:message_created, message}, socket) do
    IO.puts("DEBUG: Received message_created event for product #{message.product_id}")

    # If the modal is open for this product, send update to the chat component
    if socket.assigns.selected_product && socket.assigns.selected_product.id == message.product_id do
      IO.puts("DEBUG: Updating chat component with new message")

      send_update(ProductChatComponent,
        id: "product-chat-#{message.product_id}",
        new_message: message
      )
    end

    {:noreply, socket}
  end

  def handle_info({:new_customer_message, _message}, socket) do
    IO.puts("DEBUG: Received new customer message for vendor")
    # Reload unread counts for vendor notification badges
    if socket.assigns.current_user && socket.assigns.current_user.is_vendor do
      unread_counts =
        MakananSegar.Chat.get_vendor_unread_counts_by_product_open_only(
          socket.assigns.current_user.id
        )

      {:noreply, assign(socket, :unread_counts, unread_counts)}
    else
      {:noreply, socket}
    end
  end

  defp category_badge_class("fish"), do: "badge-info"
  defp category_badge_class("vegetables"), do: "badge-success"
  defp category_badge_class("fruits"), do: "badge-warning"
  defp category_badge_class(_), do: "badge-ghost"

  defp format_time_until_expiry(expires_at) do
    now = DateTime.now!("Asia/Kuala_Lumpur")
    diff_seconds = DateTime.diff(expires_at, now, :second)

    cond do
      diff_seconds < 3600 ->
        minutes = div(diff_seconds, 60)
        "in #{minutes} min"

      diff_seconds < 86400 ->
        hours = div(diff_seconds, 3600)
        "in #{hours} hr"

      true ->
        days = div(diff_seconds, 86400)
        "in #{days} days"
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
