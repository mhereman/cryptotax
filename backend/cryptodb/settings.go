package cryptodb

import "database/sql"

type Settings struct {
	Id            int
	SettingsName  string
	SettingsValue sql.NullString
}

type SettingsList []Settings

func (s SettingsList) Value(name string) (ok bool, v string) {
	ok = false
	v = ""
	for _, setting := range s {
		if setting.SettingsName == name {
			v = setting.SettingsValue.String
			ok = true
			break
		}
	}
	return
}

func LoadSettings() (SettingsList, error) {
	const query = `SELECT Id, SettingsName, SettingsValue FROM crypto.Settings;`
	rows, err := db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	settings := make([]Settings, 0)
	for rows.Next() {
		var s Settings
		err := rows.Scan(&s.Id, &s.SettingsName, &s.SettingsValue)
		if err != nil {
			return nil, err
		}
		settings = append(settings, s)
	}
	return settings, nil
}
