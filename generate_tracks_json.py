import pandas as pd
import json

excel_file = "General.xlsx"

df = pd.read_excel(excel_file)

tracks = []

for _, row in df.iterrows():

    year = ""

    if pd.notna(row.get("Release Date")):
        try:
            year = str(pd.to_datetime(
                row["Release Date"]
            ).year)
        except:
            year = str(row["Release Date"])

    tracks.append({
        "qrCode": str(row["za_id"]).strip(),
        "title": str(row["Track Name"]).strip(),
        "artist": str(row["Artist Name(s)"]).strip(),
        "year": year,
        "spotifyUri": str(
            row.get("Track URI", "")
        ).strip(),
        "deezerId": str(
            row.get("deezer_id", "")
        ).strip(),
        "appleMusicId": str(
            row.get("appleMusicId",
                row.get("apple_music_id",
                    row.get("Apple Music ID",
                        row.get("Apple Music Track ID", "")
                    )
                )
            )
        ).strip()
    })

with open(
    "tracks.json",
    "w",
    encoding="utf-8"
) as f:

    json.dump(
        tracks,
        f,
        ensure_ascii=False,
        indent=2
    )

print(
    f"{len(tracks)} cartes exportées."
)
