from enum import StrEnum

class Role(StrEnum):
    CUSTOMER = 'CUSTOMER'
    ADMIN = 'ADMIN'

class Status(StrEnum):
    PENDING = 'PENDING'
    PAID = 'PAID'
    CONFIRMED = 'CONFIRMED'
    DRIVER_ASSIGNED = 'DRIVER_ASSIGNED'
    PAYMENT_FAILED = 'PAYMENT_FAILED'
    FAILED = 'FAILED'

TERMINAL = {Status.DRIVER_ASSIGNED, Status.PAYMENT_FAILED, Status.FAILED}
TRANSITIONS = {
    Status.PENDING: {Status.PAID, Status.PAYMENT_FAILED},
    Status.PAID: {Status.CONFIRMED, Status.FAILED},
    Status.CONFIRMED: {Status.DRIVER_ASSIGNED, Status.FAILED},
}
EXPECTED = {'payment': ('order.created', Status.PENDING),
            'restaurant': ('order.paid', Status.PAID),
            'delivery': ('order.confirmed', Status.CONFIRMED)}
RANK = {Status.PENDING:1, Status.PAID:2, Status.CONFIRMED:3}
FAILURES = {
    'PAYMENT_DECLINED':'The simulated payment was declined. No real payment was taken.',
    'PAYMENT_RETRIES_EXHAUSTED':'Payment processing could not finish after the allowed retries.',
    'RESTAURANT_UNAVAILABLE':'The restaurant could not accept this order. No refund is claimed.',
    'DELIVERY_UNAVAILABLE':'A simulated driver could not be assigned. No refund is claimed.',
    'RESTAURANT_RETRIES_EXHAUSTED':'Restaurant confirmation could not finish after retries.',
    'DELIVERY_RETRIES_EXHAUSTED':'Driver assignment could not finish after retries.',
}
