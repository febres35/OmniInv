"""Models for the application."""

from ._rate import Rate
from ._make import Make
from ._image import Image
from ._model import Model
from ._status import Status
from ._formats import Format
from ._quality import Quality
from ._partner import Partner
from ._product import Product
from ._category import Category
from ._currency import Currency
from ._unit_measure import UnitMeasure
from ._partner_type import PartnerType
from ._product_image import ProductImage
from ._inventory_shrinkage import InventoryShrinkage
from ._shrinkage_reasons import ShrinkageReason
from ._purchese_orders import PurchaseOrder
from ._purchese_order_detail import PurchaseOrderDetail
from ._warehouses import Warehouse
from ._inventory import Inventory
from ._inventory_movements import InventoryMovement
from ._dispatch_orders import DispatchOrder
from ._dispatch_order_details import DispatchOrderDetail
from ._dispatch_routes import DispatchRoute
from ._dispatch_route_assignments import DispatchRouteAssignment
from .auth_user import (
    User,
    Profile,
    ProfileRol,
    Rol,
    AuthUser,
    UserReports,
    Credential,
    Group,
    Permissions,
    PermissionsLevel,
)

__all__ = [
    "User",
    "Profile",
    "ProfileRol",
    "Rol",
    "AuthUser",
    "UserReports",
    "Credential",
    "Group",
    "Permissions",
    "PermissionsLevel",
    "Partner",
    "Product",
    "ProductImage",
    "Category",
    "Image",
    "Status",
    "PartnerType",
    "UserReports",
    "Currency",
    "Quality",
    "Format",
    "Model",
    "Make",
    "UnitMeasure",
    "Rate",
    "InventoryShrinkage",
    "ShrinkageReason",
    "PurchaseOrder",
    "PurchaseOrderDetail",
    "Warehouse",
    "Inventory",
    "InventoryMovement",
    "DispatchOrder",
    "DispatchOrderDetail",
    "DispatchRoute",
    "DispatchRouteAssignment",
]
