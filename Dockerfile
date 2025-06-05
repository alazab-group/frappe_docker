FROM alpine:3.14 as builder

# نسخ ملف التطبيقات
COPY apps.json /tmp/apps.json

# تثبيت التبعيات الأساسية
RUN apk add --no-cache git python3 py3-pip mariadb-client

# إنشاء بيئة Frappe من مستودعات Alazab فقط
RUN python3 -m venv /venv && \
    /venv/bin/pip install frappe-bench && \
    bench init /frappe-bench --skip-assets && \
    cd /frappe-bench && \
    bench get-app frappe https://github.com/alazab-group/frappe.git && \
    bench get-app erpnext https://github.com/alazab-group/erpnext.git

# المرحلة النهائية
FROM alazab-group/frappe_docker:${ERPNEXT_VERSION}

# نسخ التطبيقات المبنية
COPY --from=builder /frappe-bench /home/frappe/frappe-bench
