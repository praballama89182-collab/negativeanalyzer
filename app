import streamlit as st
import pandas as pd
import io
import analyzer 

st.set_page_config(page_title="PPC Master Tool", layout="wide")

st.sidebar.header("Keywords")
brand_input = st.sidebar.text_area("Brand Keywords", "ooze, creation lamis, scion, maison")
brand_list = [b.strip().lower() for b in brand_input.replace('\n', ',').split(',') if b.strip()]

st.title("📊 Global PPC Search Term Analyzer")

uploaded_files = st.file_uploader("Upload Reports", type=["xlsx", "csv"], accept_multiple_files=True)

if uploaded_files:
    try:
        raw_dfs = []
        master_tabs = {}

        for file in uploaded_files:
            if file.name.endswith('.xlsx'):
                sheets = pd.read_excel(file, sheet_name=None)
                for s_name, df in sheets.items():
                    df = analyzer.clean_headers(df)
                    master_tabs[f"{file.name}_{s_name}"] = df
                    if any('Search Term' in str(c) for c in df.columns):
                        raw_dfs.append(df)
            else:
                df = pd.read_csv(file)
                df = analyzer.clean_headers(df)
                master_tabs[file.name] = df
                raw_dfs.append(df)

        if raw_dfs:
            final_df = analyzer.standardize_and_group(raw_dfs, brand_list)
            
            st.subheader("Account Totals")
            c1, c2, c3 = st.columns(3)
            c1.metric("Spend", f"{final_df['Spend'].sum():,.2f}")
            c2.metric("Sales", f"{final_df['Sales'].sum():,.2f}")
            c3.metric("Orders", f"{int(final_df['Orders'].sum())}")

            st.divider()
            st.dataframe(final_df, use_container_width=True)

            # Export
            output = io.BytesIO()
            with pd.ExcelWriter(output, engine='xlsxwriter') as writer:
                for name, df in master_tabs.items():
                    df.to_excel(writer, sheet_name=name[:30], index=False)
                final_df.to_excel(writer, sheet_name="Final Analysis", index=False)
            
            st.download_button("📥 Download All", output.getvalue(), "Consolidated_PPC.xlsx")

    except Exception as e:
        st.error(f"Error: {e}")
