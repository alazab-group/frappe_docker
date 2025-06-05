# Dockerfile لبناء صورة مخصصة للـ frappe + apps

FROM frappe/erpnext:${ERPNEXT_VERSION}

LABEL maintainer="Alazab Tech <admin@alazab.online>"

# تثبيت أدوات إضافية أو نسخ التطبيقات من المستودع الحالي
COPY apps /home/frappe/frappe-bench/apps

# إعداد مسارات المواقع
COPY sites /home/frappe/frappe-bench/sites

# تنفيذ الأمر الافتراضي
CMD ["bench", "start"]
