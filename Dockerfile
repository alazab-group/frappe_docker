# ──────────────────────────────────────────────────────────────
# Dockerfile للتطبيقات المخصصة - العزب جروب
# ──────────────────────────────────────────────────────────────

ARG ERPNEXT_VERSION=v15.63.0
ARG FRAPPE_VERSION=v15.63.0

# استخدام الصورة الرسمية كقاعدة
FROM frappe/erpnext:${ERPNEXT_VERSION}

# التبديل للمستخدم root لتثبيت التبعيات
USER root

# تثبيت الأدوات المطلوبة
RUN apt-get update && apt-get install -y \
    jq \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# التبديل للمستخدم frappe
USER frappe

# تعيين مجلد العمل
WORKDIR /home/frappe/frappe-bench

# نسخ ملف التطبيقات
COPY --chown=frappe:frappe apps.json ./

# تحميل التطبيقات المخصصة
RUN set -e && \
    # قراءة وتحميل كل تطبيق من apps.json
    jq -r '.[] | @base64' apps.json | while read app; do \
        APP_DATA=$(echo "$app" | base64 -d); \
        APP_NAME=$(echo "$APP_DATA" | jq -r '.name'); \
        APP_URL=$(echo "$APP_DATA" | jq -r '.url'); \
        APP_BRANCH=$(echo "$APP_DATA" | jq -r '.branch // "main"'); \
        \
        # تخطي frappe وerpnext لأنهما موجودان بالفعل
        if [ "$APP_NAME" != "frappe" ] && [ "$APP_NAME" != "erpnext" ]; then \
            echo "تحميل تطبيق: $APP_NAME من $APP_URL (فرع: $APP_BRANCH)"; \
            bench get-app --branch="$APP_BRANCH" "$APP_NAME" "$APP_URL" || { \
                echo "فشل في تحميل $APP_NAME، المحاولة بفرع main"; \
                bench get-app "$APP_NAME" "$APP_URL"; \
            }; \
        fi; \
    done

# تنظيف ملفات .git لتوفير المساحة
RUN find apps -name ".git" -type d -exec rm -rf {} + 2>/dev/null || true

# إنشاء قائمة التطبيقات
RUN ls -1 apps > sites/apps.txt

# تعيين الصلاحيات
USER root
RUN chown -R frappe:frappe /home/frappe/frappe-bench
USER frappe

# متغيرات البيئة
ENV PYTHONPATH=/home/frappe/frappe-bench/apps
ENV PATH=/home/frappe/frappe-bench/env/bin:$PATH

# Volume للمواقع
VOLUME ["/home/frappe/frappe-bench/sites"]

# أمر التشغيل الافتراضي
CMD ["gunicorn", "--chdir=/home/frappe/frappe-bench/sites", "--bind=0.0.0.0:8000", "--threads=4", "--workers=2", "--worker-class=gthread", "--worker-tmp-dir=/dev/shm", "--timeout=120", "--preload", "frappe.app:application"]
