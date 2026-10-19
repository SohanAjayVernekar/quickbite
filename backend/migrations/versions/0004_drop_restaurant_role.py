"""Remove the restaurant owner role; keep the refund lifecycle.

Restaurant acceptance stays automatic, so there is no restaurant-facing
identity to support. The refund_records table is retained deliberately: admin
cancellation needs somewhere to record what is owed, which is what the
administrator replaces the read-only console with.
"""
from alembic import op

revision = "0004"
down_revision = "0003"
branch_labels = None
depends_on = None


def upgrade():
    op.execute("DELETE FROM users WHERE role = 'RESTAURANT'")
    op.execute("ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_restaurant_check")
    op.execute("ALTER TABLE users DROP CONSTRAINT IF EXISTS fk_users_restaurant")
    op.execute("DROP INDEX IF EXISTS ix_users_restaurant_id")
    op.execute("ALTER TABLE users DROP COLUMN IF EXISTS restaurant_id")
    op.execute("ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check")
    op.execute(
        "ALTER TABLE users ADD CONSTRAINT users_role_check "
        "CHECK (role IN ('CUSTOMER','ADMIN'))"
    )


def downgrade():
    op.execute(
        "ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check"
    )
    op.execute(
        "ALTER TABLE users ADD CONSTRAINT users_role_check "
        "CHECK (role IN ('CUSTOMER','ADMIN','RESTAURANT'))"
    )
    op.execute("ALTER TABLE users ADD COLUMN restaurant_id VARCHAR(64)")
    op.execute("CREATE INDEX ix_users_restaurant_id ON users (restaurant_id)")
    op.execute(
        "ALTER TABLE users ADD CONSTRAINT fk_users_restaurant "
        "FOREIGN KEY (restaurant_id) REFERENCES restaurants (id) "
        "ON DELETE SET NULL"
    )
    op.execute(
        "ALTER TABLE users ADD CONSTRAINT users_role_restaurant_check CHECK ("
        "(role = 'RESTAURANT' AND restaurant_id IS NOT NULL) OR "
        "(role <> 'RESTAURANT' AND restaurant_id IS NULL))"
    )
