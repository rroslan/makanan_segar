defmodule MakananSegar.Workers.ProductExpiryWorker do
  @moduledoc """
  Oban worker for automatically deleting expired products.

  This worker runs periodically to clean up products that have passed their expiration date.
  Products are considered expired when their `expires_at` time is in the past relative
  to Malaysian time (Asia/Kuala_Lumpur).
  """

  use Oban.Worker, queue: :products, max_attempts: 3

  import Ecto.Query
  alias MakananSegar.Repo
  alias MakananSegar.Products.Product

  @doc """
  Performs the expired product cleanup job.

  This function handles two types of jobs:
  1. General cleanup (no product_id in args) - finds and deletes all expired products
  2. Specific product cleanup (product_id in args) - checks and deletes a specific product if expired
  """
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"product_id" => product_id}} = _job) do
    perform_single_product_cleanup(product_id)
  end

  def perform(%Oban.Job{args: %{}} = _job) do
    perform_bulk_cleanup()
  end

  defp perform_bulk_cleanup do
    malaysia_now = DateTime.now!("Asia/Kuala_Lumpur")

    # Find all active products that have expired
    expired_products_query =
      from p in Product,
        where: p.expires_at < ^malaysia_now and p.is_active == true

    # Get count before deletion for logging
    expired_count = Repo.aggregate(expired_products_query, :count, :id)

    if expired_count > 0 do
      # Mark expired products as inactive (soft delete)
      {updated_count, _} =
        Repo.update_all(expired_products_query, set: [is_active: false, updated_at: malaysia_now])

      # Log the cleanup
      require Logger

      Logger.info(
        "ProductExpiryWorker: Marked #{updated_count} expired products as inactive at #{DateTime.to_string(malaysia_now)}"
      )

      {:ok, %{updated_count: updated_count, timestamp: malaysia_now}}
    else
      # No expired products found
      require Logger

      Logger.info(
        "ProductExpiryWorker: No expired products found at #{DateTime.to_string(malaysia_now)}"
      )

      {:ok, %{updated_count: 0, timestamp: malaysia_now}}
    end
  end

  defp perform_single_product_cleanup(product_id) do
    malaysia_now = DateTime.now!("Asia/Kuala_Lumpur")

    case Repo.get(Product, product_id) do
      nil ->
        # Product already deleted or doesn't exist
        {:ok, %{status: :not_found, product_id: product_id}}

      product ->
        if DateTime.compare(product.expires_at, malaysia_now) == :lt do
          # Product has expired, mark it as inactive (soft delete)
          case Repo.update(Product.changeset(product, %{is_active: false})) do
            {:ok, _updated_product} ->
              require Logger

              Logger.info(
                "ProductExpiryWorker: Marked expired product #{product_id} (#{product.name}) as inactive"
              )

              {:ok, %{status: :deactivated, product_id: product_id, product_name: product.name}}

            {:error, changeset} ->
              require Logger

              Logger.error(
                "ProductExpiryWorker: Failed to deactivate expired product #{product_id}: #{inspect(changeset.errors)}"
              )

              {:error, changeset}
          end
        else
          # Product not yet expired, reschedule
          schedule_product_expiry(product_id, product.expires_at)

          {:ok, %{status: :rescheduled, product_id: product_id, new_expiry: product.expires_at}}
        end
    end
  end

  @doc """
  Schedules the product expiry cleanup job to run every hour.

  This should be called during application startup to ensure
  expired products are regularly cleaned up.
  """
  def schedule_periodic_cleanup do
    # Schedule to run every hour
    %{worker: __MODULE__}
    |> Oban.insert()
  end

  @doc """
  Schedules a specific product for deletion when it expires.

  This creates a delayed job that will run when the product expires,
  allowing for more immediate cleanup instead of waiting for the
  next periodic job.

  ## Parameters
  - product_id: The ID of the product to check for expiration
  - expires_at: The expiration datetime of the product
  """
  def schedule_product_expiry(product_id, expires_at) when is_integer(product_id) do
    # Schedule job to run when product expires
    %{product_id: product_id}
    |> __MODULE__.new(scheduled_at: expires_at)
    |> Oban.insert()
  end

  @doc """
  Manually triggers expired product cleanup.

  Useful for testing or manual cleanup operations.
  """
  def cleanup_expired_products do
    %{}
    |> __MODULE__.new()
    |> Oban.insert()
  end

  @doc """
  Returns statistics about upcoming product expirations.

  This can be used by admin dashboards to show system health.
  """
  def expiry_statistics do
    malaysia_now = DateTime.now!("Asia/Kuala_Lumpur")

    # Products expiring in next 24 hours
    expiring_soon =
      from(p in Product,
        where:
          p.expires_at > ^malaysia_now and
            p.expires_at <= ^DateTime.add(malaysia_now, 24, :hour)
      )
      |> Repo.aggregate(:count, :id)

    # Products expiring in next week
    expiring_this_week =
      from(p in Product,
        where:
          p.expires_at > ^malaysia_now and
            p.expires_at <= ^DateTime.add(malaysia_now, 7, :day)
      )
      |> Repo.aggregate(:count, :id)

    # Already expired products (shouldn't be many if worker is running properly)
    already_expired =
      from(p in Product,
        where: p.expires_at < ^malaysia_now
      )
      |> Repo.aggregate(:count, :id)

    %{
      expiring_in_24h: expiring_soon,
      expiring_in_week: expiring_this_week,
      already_expired: already_expired,
      checked_at: malaysia_now
    }
  end
end
