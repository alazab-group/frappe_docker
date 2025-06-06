# مرحلة البناء (Builder)
FROM alpine:3.14 as builder

# تثبيت التبعيات الأساسية
RUN apk add --no-cache \
    git \
    python3 \
    py3-pip \
    mariadb-client \
    gcc \
    musl-dev \
    python3-dev \
    mariadb-dev

# إنشاء بيئة افتراضية وتهيئة Bench
RUN python3 -m venv /venv && \
    /venv/bin/pip install --upgrade pip && \
    /venv/bin/pip install frappe-bench

# تهيئة بيئة Frappe (بدون أصول)
RUN bench init /frappe-bench \
    --skip-assets \
    --frappe-branch ${FRAPPE_VERSION:-version-14} \
    --frappe-path https://github.com/alazab-group/frappe.git && \
    cd /frappe-bench

# تثبيت التطبيقات الأساسية من مستودعات Alazab
RUN cd /frappe-bench && \
    bench get-app erpnext \
    https://github.com/alazab-group/erpnext.git \
    --branch ${ERPNEXT_VERSION:-version-14}

# نسخ ملف apps.json ومعالجة التطبيقات الإضافية
COPY apps.json /tmp/apps.json
RUN cd /frappe-bench && \
    jq -c '.[]' /tmp/apps.json | while read app; do \
        name=$(echo "$app" | jq -r '.name'); \
        url=$(echo "$app" | jq -r '.url'); \
        branch=$(echo "$app" | jq -r '.branch // "main"'); \
        if [ "$name" != "frappe" ] && [ "$name" != "erpnext" ]; then \
            bench get-app "$name" "$url" --branch "$branch"; \
        fi; \
    done

# المرحلة النهائية
FROM alazab-group/frappe_docker:${ERPNEXT_VERSION:-version-14}

# نسخ البيئة المبنية
COPY --from=builder /frappe-bench/apps /home/frappe/frappe-bench/apps
COPY --from=builder /venv /home/frappe/venv

# تعيين أذونات المستخدم
RUN chown -R frappe:frappe /home/frappe

# متغيرات بيئية إضافية
ENV PATH="/home/frappe/venv/bin:$PATH" \
    FRAPPE_VERSION=${FRAPPE_VERSION:-version-14} \
    ERPNEXT_VERSION=${ERPNEXT_VERSION:-version-14}

# نقطة الدخول
ENTRYPOINT ["/home/frappe/venv/bin/bench"]
CMD ["start"]
