from fastapi import APIRouter

from app.api.routes import (
    addresses,
    admin,
    auth,
    business_hours,
    catalog,
    coupons,
    delivery,
    health,
    notifications,
    observability,
    orders,
    payments,
    pricing,
    realtime,
)

api_router = APIRouter()
api_router.include_router(health.router, tags=["health"])
api_router.include_router(auth.router, tags=["auth"])
api_router.include_router(addresses.router, tags=["customer-addresses"])
api_router.include_router(catalog.router, tags=["catalog"])
api_router.include_router(catalog.admin_router, tags=["admin-catalog"])
api_router.include_router(pricing.router, tags=["pricing"])
api_router.include_router(orders.router, tags=["orders"])
api_router.include_router(orders.admin_router, tags=["admin-orders"])
api_router.include_router(payments.router, tags=["payments"])
api_router.include_router(payments.admin_router, tags=["admin-payments"])
api_router.include_router(admin.router, tags=["admin-dashboard"])
api_router.include_router(business_hours.router, tags=["business-hours"])
api_router.include_router(business_hours.admin_router, tags=["admin-hours"])
api_router.include_router(delivery.router, tags=["delivery"])
api_router.include_router(delivery.admin_router, tags=["admin-delivery"])
api_router.include_router(delivery.locations_admin_router, tags=["admin-coverage-locations"])
api_router.include_router(coupons.router, tags=["admin-coupons"])
api_router.include_router(observability.router, tags=["observability"])
api_router.include_router(realtime.router, tags=["realtime"])
api_router.include_router(notifications.router, tags=["notifications"])
