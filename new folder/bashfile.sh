#!/bin/bash

# بررسی اینکه آیا آرگومان ورودی داده شده است
if [[ -z "$1" ]]; then
    echo "لطفا مسیر فایل pass.txt را وارد کنید."
    exit 1
fi

# خواندن آدرس فایل رمز از آرگومان ورودی
password_file="$1"

# بررسی وجود فایل
if [[ ! -f "$password_file" ]]; then
    echo "فایل ${password_file} یافت نشد."
    exit 1
fi

# پردازش هر خط در فایل رمز
while IFS= read -r line; do
    # استخراج نام فایل زیپ (بخش test1، test2 یا test3) و رمز بین <>
    zip_name=$(echo "$line" | grep -oE '^(test[123])')
    password=$(echo "$line" | grep -oE '<[^<>]{8,20}>' | sed 's/[<>]//g')

    # بررسی اینکه آیا نام فایل و رمز استخراج شدهاند یا خیر
    if [[ -n "$zip_name" && -n "$password" ]]; then
        # ساخت نام فایل زیپ
        zip_file="${zip_name}.zip"
        
        # چک کردن وجود فایل زیپ
        if [[ -f "$zip_file" ]]; then
            echo "در حال استخراج $zip_file با رمز $password"
            # استخراج فایل زیپ با رمز
            extract_dir="./${zip_name}_extracted"
            unzip -P "$password" "$zip_file" -d "$extract_dir"

            # پاک کردن فایلهایی که فرمت آنها غیر از txt است
            find "$extract_dir" -type f ! -name "*.txt" -exec rm {} +

            # دستهبندی فایلهای txt باقیمانده بر اساس حرف اول نام فایل
            for txt_file in "$extract_dir"/*.txt; do
                # اگر فایل txt موجود است
                if [[ -f "$txt_file" ]]; then
                    first_letter=$(basename "$txt_file" | cut -c 1 | tr '[:lower
:]
' '[:upper:]')
                    # ساخت دایرکتوری برای دستهبندی بر اساس حرف اول فایل
                    mkdir -p "$extract_dir/$first_letter"
                    # جابجایی فایل به دایرکتوری مربوطه
                    mv "$txt_file" "$extract_dir/$first_letter/"
                fi
            done
        else
            echo "فایل زیپ ${zip_file} یافت نشد."
        fi
    fi
done < "$password_file"

