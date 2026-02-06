from mypy.plugin import Plugin, ClassDefContext, AttributeContext
from mypy.plugins.common import add_attribute_to_class
from mypy.types import NoneType, UnionType


class SympyPlugin(Plugin):
    """MyPy plugin for sympy.core.basic.Basic to add assumptions and free_symbols typing."""

    def get_base_class_hook(self, fullname: str):
        """Return hook for adding assumption attributes to Basic subclasses."""
        if fullname == "sympy.core.basic.Basic":
            return add_assumptions
        return None

    def get_attribute_hook(self, fullname: str):
        """Return hook for specific attributes to override types."""
        if fullname == "sympy.core.basic.Basic.free_symbols":
            return free_symbols_type
        return None


def add_assumptions(ctx: ClassDefContext) -> None:
    """Adds is_<assumption>: Optional[bool] attributes to a sympy.Basic subclass."""
    assumptions = [
        "hermitian", "prime", "noninteger", "negative", "antihermitian",
        "infinite", "finite", "irrational", "extended_positive",
        "nonpositive", "odd", "algebraic", "integer", "rational",
        "extended_real", "nonnegative", "transcendental", "extended_nonzero",
        "extended_negative", "composite", "complex", "imaginary", "nonzero",
        "zero", "even", "positive", "polar", "extended_nonpositive",
        "extended_nonnegative", "real", "commutative",
    ]
    for a in assumptions:
        add_attribute_to_class(
            ctx.api,
            ctx.cls,
            f"is_{a}",
            UnionType([ctx.api.named_type("builtins.bool"), NoneType()]),
        )


def free_symbols_type(ctx: AttributeContext):
    """Override type of Basic.free_symbols to Set[sympy.Symbol]."""
    return ctx.api.named_generic_type(
        "builtins.set", [ctx.api.named_type("sympy.Symbol")]
    )


def plugin(version: str):
    """Entry point for MyPy plugin."""
    return SympyPlugin
