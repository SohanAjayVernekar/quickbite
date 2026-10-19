"""Restaurant owner identity and an explicit refund lifecycle.

This is groundwork only. It adds the concepts restaurant approval needs without
introducing an approval gate:

  * users.role accepts 'RESTAURANT'
  * users.restaurant_id links an owner to a restaurant
  * a refunds table records obligations, so a later rejection has somewhere to go

No order state machine behaviour changes here. Transitions into the refund
states are added separately and deliberately, because adding them at the same
time as the schema would risk stranding live orders mid-pipeline.
"""
from alembic import op

revision = "0003"
down_revision = "0002"
branch_labels = None
depends_on = None


def upgrade():
    # Widen the role check rather than recreating the table: users and orders
    # hold live data and orders reference users.
    op.execute(
        "ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check"
    )
    op.execute(
        "ALTER TABLE users ADD CONSTRAINT users_role_check "
        "CHECK (role IN ('CUSTOMER','ADMIN','RESTAURANT'))"
    )
    op.execute("ALTER TABLE users ADD COLUMN restaurant_id VARCHAR(64)")
    op.execute(
        "CREATE INDEX ix_users_restaurant_id ON users (restaurant_id)"
    )
    op.execute(
        "ALTER TABLE users ADD CONSTRAINT fk_users_restaurant "
        "FOREIGN KEY (restaurant_id) REFERENCES restaurants (id) "
        "ON DELETE SET NULL"
    )

    # A restaurant owner belongs to a restaurant; customers and admins do not.
    op.execute(
        "ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_restaurant_check"
    )
    op.execute(
        "ALTER TABLE users ADD CONSTRAINT users_role_restaurant_check CHECK ("
        "(role = 'RESTAURANT' AND restaurant_id IS NOT NULL) OR "
        "(role <> 'RESTAURANT' AND restaurant_id IS NULL))"
    )

    op.execute(
        """
        CREATE TABLE refund_records (
            id VARCHAR(64) NOT NULL,
            order_id VARCHAR(64) NOT NULL,
            payment_id VARCHAR(64),
            amount_minor BIGINT NOT NULL,
            currency VARCHAR(3) NOT NULL,
            reason VARCHAR(40) NOT NULL,
            status VARCHAR(20) NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE NOT NULL,
            completed_at TIMESTAMP WITH TIME ZONE,
            PRIMARY KEY (id),
            UNIQUE (order_id),
            CHECK (amount_minor >= 0),
            CHECK (status IN ('PENDING','COMPLETED','FAILED')),
            CHECK (reason IN ('RESTAURANT_REJECTED','RESTAURANT_UNAVAILABLE','CUSTOMER_CANCELLED','DUPLICATE_ORDER','GOODWILL')),
            FOREIGN KEY (order_id) REFERENCES orders (id),
            FOREIGN KEY (payment_id) REFERENCES simulated_payments (id)
        )
        """
    )
    op.execute(
        "CREATE INDEX ix_refund_records_status ON refund_records (status)"
    )


def downgrade():
    op.execute("DROP INDEX IF EXISTS ix_refund_records_status")
    op.execute("DROP TABLE IF EXISTS refund_records")
    op.execute(
        "ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_restaurant_check"
    )
    op.execute("ALTER TABLE users DROP CONSTRAINT IF EXISTS fk_users_restaurant")
    op.execute("DROP INDEX IF EXISTS ix_users_restaurant_id")
    op.execute("ALTER TABLE users DROP COLUMN restaurant_id")
    op.execute(
        "ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check"
    )
    op.execute(
        "ALTER TABLE users ADD CONSTRAINT users_role_check "
        "CHECK (role IN ('CUSTOMER','ADMIN'))"
    )
