# ──────────────────────────────────────────────────────────────
# المرحلة الأولى: إعداد بيئة البناء (builder)
# ──────────────────────────────────────────────────────────────
FROM alpine:3.14 AS builder

# تثبيت التبعيات الأساسية
RUN apk add --no-cache \
    git \
    python3 \
    py3-pip \
    mariadb-client \
    gcc \
    musl-dev \
    python3-dev \
    mariadb-dev \
    jq

# تهيئة البيئة الافتراضية وbench
RUN python3 -m venv /venv && \
    /venv/bin/pip install --upgrade pip && \
    /venv/bin/pip install frappe-bench

# إنشاء مشروع frappe-bench
ARG FRAPPE_VERSION=version-15
RUN /venv/bin/bench init /frappe-bench \
    --skip-assets \
    --frappe-branch ${FRAPPE_VERSION}

# نسخ ملف التطبيقات المخصصة
COPY apps.json /frappe-bench/apps.json

# تحميل التطبيقات من apps.json (عدا frappe وerpnext)
WORKDIR /frappe-bench
RUN jq -c '.[]' apps.json | while read app; do \
    name=$(echo "$app" | jq -r '.name'); \
    url=$(echo "$app" | jq -r '.url'); \
    branch=$(echo "$app" | jq -r '.branch // "main"'); \
    if [ "$name" != "frappe" ] && [ "$name" != "erpnext" ]; then \
        /venv/bin/bench get-app "$name" "$url" --branch "$branch"; \
    fi; \
done

# ──────────────────────────────────────────────────────────────
# المرحلة الثانية: إنشاء صورة التشغيل النهائية
# ──────────────────────────────────────────────────────────────
FROM frappe/erpnext:${ERPNEXT_VERSION:-version-15}

# نسخ التطبيقات والبيئة الافتراضية من مرحلة البناء
COPY --from=builder /frappe-bench/apps /home/frappe/frappe-bench/apps
COPY --from=builder /venv /home/frappe/venv

# تعيين الصلاحيات
RUN chown -R frappe:frappe /home/frappe

# إعداد البيئة
ENV PATH="/home/frappe/venv/bin:$PATH"

# نقطة التشغيل (افتراضيًا لا يتم تشغيل أمر bench هنا)
ENTRYPOINT ["/bin/bash"]

