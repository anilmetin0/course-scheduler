#!/usr/bin/env python3
"""
Excel/TSV/CSV dosyasını JSON formatına çeviren script
"""
import json
import re
from collections import Counter
from pathlib import Path
from typing import Optional
from datetime import datetime
import pandas as pd
 
# Not: Türkçe karakter düzeltme fonksiyonları artık gerekli değil.
 
def _sniff_delimiter(sample_text: str) -> str:
    """
    Basit ayraç tespiti: sekme (TSV) ya da virgül (CSV).
    Sekme sayısı virgülden fazlaysa '\t', aksi halde ',' döner.
    """
    first_line = sample_text.splitlines()[0] if sample_text else ""
    tabs = first_line.count("\t")
    commas = first_line.count(",")
    if tabs > commas:
        return "\t"
    return ","
 
def _looks_like_text_table(path: Path) -> Optional[str]:
    """
    Dosya bir metin tablosu (TSV/CSV) gibi görünüyor mu?
    Evetse kullanılacak ayraç ('\\t' veya ',') döndürür, aksi halde None.
    """
    try:
        with open(path, "rb") as f:
            sample = f.read(4096)
        # Eğer ilk baytlar arasında kontrol karakterleri yoksa ve metin ağırlıklıysa
        text = sample.decode("utf-8", errors="ignore")
        # Çok sayıda NUL veya ikili başlık yoksa metin say
        if b"\\x00" in sample[:64]:
            return None
        # Sekme veya virgül barındırıyorsa metin tablosudur
        if ("\t" in text) or ("," in text):
            return _sniff_delimiter(text)
    except Exception:
        return None
    return None
 
def _postprocess_df(df: pd.DataFrame) -> pd.DataFrame:
    """
    Okunan DataFrame için genel temizlik:
    - Tamamen boş (NaN veya boş string) sütunları at
    - İsimsiz sütunları (Unnamed) ve tümü boş olanları düşür
    - Baş-son boşlukları kırp
    """
    # Sütun adlarını string'e çevir
    df.columns = [str(c) if c is not None else "" for c in df.columns]
    # Hücreleri string yap, baş/son boşluk kırp
    if hasattr(df, "applymap"):
        df = df.applymap(lambda v: v.strip() if isinstance(v, str) else v)
    else:
        # pandas >= 2.2 ile applymap kaldırıldı; map ile eşdeğer davranış
        df = df.apply(lambda col: col.map(lambda v: v.strip() if isinstance(v, str) else v))
    # Tamamen boş sütunları ele
    def _col_all_empty(series: pd.Series) -> bool:
        return series.isna().all() or (series.fillna("").astype(str).str.strip() == "").all()
    empty_cols = [c for c in df.columns if _col_all_empty(df[c])]
    if empty_cols:
        print(f"Temizlik: Tamamen boş sütunlar atıldı: {empty_cols}")
        df = df.drop(columns=empty_cols)
    # 'Unnamed' ile başlayan sütun adlarını ve boş isimli sütunları, eğer tümü boşsa at
    drop_candidates = [c for c in df.columns if c.startswith("Unnamed") or c.strip() == ""]
    truly_empty = [c for c in drop_candidates if _col_all_empty(df[c])]
    if truly_empty:
        print(f"Temizlik: İsimsiz ve boş sütunlar atıldı: {truly_empty}")
        df = df.drop(columns=truly_empty)
    return df

def _normalize_cell_value(value) -> str:
    """
    Hücre değerini string'e dönüştürür, boşlukları kırpar ve
    sayısal görünümlerdeki gereksiz '.0' eklerini temizler.
    """
    if value is None:
        return ""
    try:
        if pd.isna(value):
            return ""
    except Exception:
        pass
    text = str(value).strip()
    if not text:
        return ""
    if re.fullmatch(r"\d+(\.0+)?", text):
        return text.split(".")[0]
    return text

def _find_column(df: pd.DataFrame, candidates) -> Optional[str]:
    lookup = {str(c).strip().lower(): c for c in df.columns}
    for name in candidates:
        key = name.lower()
        if key in lookup:
            return lookup[key]
    return None

def _most_common_non_empty(series: pd.Series, label: str) -> str:
    values = [_normalize_cell_value(v) for v in series.tolist()]
    values = [v for v in values if v]
    if not values:
        raise ValueError(f"{label} değeri bulunamadı.")
    counts = Counter(values)
    value, _ = counts.most_common(1)[0]
    if len(counts) > 1:
        others = {k: v for k, v in counts.items() if k != value}
        print(f"Uyarı: {label} sütununda farklı değerler bulundu. En sık olan kullanılacak: {value}. Diğerleri: {others}")
    return value

def _derive_dataset_stem(df: pd.DataFrame) -> str:
    year_col = _find_column(df, ["year"])
    period_col = _find_column(df, ["period"])
    if not year_col or not period_col:
        raise ValueError("Year/Period sütunları bulunamadı.")

    year_value = _most_common_non_empty(df[year_col], "Year")
    period_value = _most_common_non_empty(df[period_col], "Period")

    year_value = _normalize_cell_value(year_value).replace(" ", "")
    period_value = _normalize_cell_value(period_value).replace(" ", "")

    if year_value.isdigit():
        start_year = int(year_value)
        year_part = f"{start_year}-{start_year + 1}"
    else:
        year_part = year_value

    period_part = period_value
    if period_part.isdigit() and len(period_part) < 3:
        period_part = period_part.zfill(3)

    return f"{year_part}_{period_part}"
 
def _read_csv_with_fallback(path: Path, sep: str) -> pd.DataFrame:
    """
    Metin tabloyu çeşitli encoding'lerle okumayı dener ve başarılı olanı döner.
    """
    encodings = [
        "utf-8",
        "utf-8-sig",
        "cp1254",       # Turkish (Windows)
        "iso-8859-9",   # Turkish (Latin 5)
        "latin1",
        "cp1252",
    ]
    last_err = None
    for enc in encodings:
        try:
            print(f"Deneme: encoding={enc}")
            return pd.read_csv(path, sep=sep, dtype=str, engine="python", encoding=enc)
        except UnicodeDecodeError as e:
            last_err = e
            continue
    if last_err:
        raise last_err
    # Teoride buraya düşmez; güvenlik için utf-8 ile dener
    return pd.read_csv(path, sep=sep, dtype=str, engine="python")

def _read_table_anyhow(path: Path, engine: Optional[str]):
    """
    Dosyayı mümkün olan en mantıklı yolla DataFrame'e okur:
    - Eğer gerçek Excel ise read_excel (verilen engine ile)
    - Değilse TSV/CSV olarak dener
    - read_excel hata verirse TSV/CSV'e geri düşer
    """
    # Ön tespit: .xls uzantılı ama metin tablosu olabilir
    delimiter = _looks_like_text_table(path)
    if delimiter:
        kind = "TSV" if delimiter == "\t" else "CSV"
        print(f"Uyarı: Dosya ikili Excel değil, {kind} gibi görünüyor. {kind} olarak okunacak.")
        df = _read_csv_with_fallback(path, sep=delimiter)
        return _postprocess_df(df)
 
    # Excel olarak dene
    try:
        df = pd.read_excel(path, engine=engine, dtype=str)
        return _postprocess_df(df)
    except Exception as e:
        msg = str(e)
        print(f"Excel okuma hatası: {msg}")
        # Yaygın durum: .xls uzantılı ama aslında metin/CSV
        delimiter = _looks_like_text_table(path)
        if delimiter:
            kind = "TSV" if delimiter == "\t" else "CSV"
            print(f"Yedek okuma: Dosya {kind} algılandı, {kind} olarak okunuyor.")
            df = _read_csv_with_fallback(path, sep=delimiter)
            return _postprocess_df(df)
        # Başka hatalarda, hatayı yeniden fırlat
        raise
 
def convert_excel_to_json(
    excel_path,
    json_path=None,
    auto_name=False,
    rename_input=False,
    return_paths=False,
):
    """Excel dosyasını JSON formatına çevirir"""
    try:
        # Dosya uzantısına göre uygun engine'i seç
        excel_path = Path(excel_path)
        json_path = Path(json_path) if json_path else None
        suffix = excel_path.suffix.lower()
        engine = None
        if suffix == ".xls":
            engine = "xlrd"
        elif suffix == ".xlsx":
            engine = "openpyxl"
        else:
            engine = None  # pandas otomatik belirlesin
        print(f"Kullanılacak engine: {engine or 'pandas (otomatik)'}")
 
        # Dosyayı oku
        df = _read_table_anyhow(excel_path, engine=engine)

        dataset_stem = None
        if auto_name:
            try:
                dataset_stem = _derive_dataset_stem(df)
                print(f"Otomatik isim: {dataset_stem}")
            except Exception as e:
                print(f"⚠️  Otomatik isimlendirme başarısız: {e}")
                dataset_stem = None

        if auto_name and dataset_stem and rename_input:
            desired_excel_path = excel_path.with_name(f"{dataset_stem}{excel_path.suffix}")
            if desired_excel_path != excel_path:
                if desired_excel_path.exists():
                    try:
                        desired_excel_path.unlink()
                        print(f"ℹ️  Var olan dosya silindi (üzerine yazmak için): {desired_excel_path.name}")
                    except Exception as e:
                        raise RuntimeError(f"Hedef dosya silinemedi: {desired_excel_path} -> {e}")
                old_name = excel_path.name
                excel_path.rename(desired_excel_path)
                excel_path = desired_excel_path
                print(f"✅ Dosya yeniden adlandırıldı: {old_name} -> {excel_path.name}")

        if json_path is None:
            if auto_name and dataset_stem:
                json_path = excel_path.with_name(f"{dataset_stem}.json")
            else:
                json_path = excel_path.with_suffix('.json')

        print(f"\nÇeviriliyor: {excel_path} -> {json_path}")
        print(f"Tablo okundu. Satır sayısı: {len(df)}")
        print(f"Sütunlar: {list(df.columns)}")
        print("\\nİlk 5 satır:")
        print(df.head())
 
        # Verileri JSON formatına çevir (doğrudan, ek karakter düzeltmesi olmadan)
        courses_data = []
        for _, row in df.iterrows():
            course_data = {}
            for col in df.columns:
                value = row[col]
                if pd.isna(value):
                    course_data[col] = ""
                else:
                    course_data[col] = str(value)
            courses_data.append(course_data)
 
        # JSON formatında kaydet
        generated_at = datetime.now().astimezone()
        output_data = {
            "courses": courses_data,
            "metadata": {
                "total_courses": len(courses_data),
                "columns": list(df.columns),
                "source": "converted_from_excel_or_text_table",
                "generated_at": generated_at.isoformat(timespec="minutes"),
            }
        }
 
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(output_data, f, ensure_ascii=False, indent=2)
 
        print(f"\\nJSON dosyası oluşturuldu: {json_path}")
        print(f"Toplam kurs sayısı: {len(courses_data)}")
        if return_paths:
            return True, excel_path, json_path
        return True
    except Exception as e:
        print(f"Hata: {e}")
        if return_paths:
            return False, None, None
        return False
 
def main():
    # Tüm uygun dosyaları assets/schedules klasöründe ara ve sırayla çevir
    assets_dir = Path("assets/schedules")
    if not assets_dir.exists() or not assets_dir.is_dir():
        print(f"assets/schedules klasörü bulunamadı: {assets_dir}")
        return

    patterns = ["*.xls", "*.xlsx", "*.csv", "*.tsv"]
    files = []
    for pat in patterns:
        files.extend(list(assets_dir.glob(pat)))

    # Tekilleştir ve sırala
    files = sorted(set(files))
    if not files:
        print("assets/schedules içinde .xls/.xlsx/.csv/.tsv dosyası bulunamadı.")
        return

    success = []
    failed = []
    for fp in files:
        try:
            if not fp.exists():
                print(f"Atlandı (dosya artık yok): {fp}")
                continue
            ok, final_excel_path, _ = convert_excel_to_json(
                fp,
                json_path=None,
                auto_name=True,
                rename_input=True,
                return_paths=True,
            )
            if ok:
                success.append(final_excel_path.name if final_excel_path else fp.name)
            else:
                failed.append(fp.name)
        except Exception as e:
            print(f"Dosya sırasında hata: {fp} -> {e}")
            failed.append(fp.name)

    print("\nİşlem özeti:")
    print(f"Toplam dosya: {len(files)}")
    print(f"Başarıyla çevrilenler: {len(success)}")
    if success:
        print("  - ", success)
    print(f"Başarısız olanlar: {len(failed)}")
    if failed:
        print("  - ", failed)
    
    # constants.dart artık otomatik güncellenmez; uygulama metadata'dan okur.
 
if __name__ == "__main__":
    main()
