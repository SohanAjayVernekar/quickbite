"""Operator triage flags on quarantined events.

Acknowledgement records that a human reviewed a dead-lettered event. It never
requeues or reprocesses the event, so it cannot cause an order to be processed
twice. The order state machine stays worker-driven.
"""
from alembic import op

revision = "0002"
down_revision = "0001"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        "ALTER TABLE quarantine_records "
        "ADD COLUMN acknowledged BOOLEAN NOT NULL DEFAULT false"
    )
    op.execute(
        "ALTER TABLE quarantine_records ADD COLUMN acknowledged_at TIMESTAMPTZ"
    )
    op.execute(
        "ALTER TABLE quarantine_records "
        "ADD COLUMN acknowledged_by VARCHAR(64)"
    )
    op.execute(
        "CREATE INDEX ix_quarantine_records_acknowledged "
        "ON quarantine_records (acknowledged)"
    )


def downgrade():
    op.execute("DROP INDEX IF EXISTS ix_quarantine_records_acknowledged")
    op.execute("ALTER TABLE quarantine_records DROP COLUMN acknowledged_by")
    op.execute("ALTER TABLE quarantine_records DROP COLUMN acknowledged_at")
    op.execute("ALTER TABLE quarantine_records DROP COLUMN acknowledged")
