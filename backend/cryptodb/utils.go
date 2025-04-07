package cryptodb

import "database/sql"

type NullString struct {
	sql.NullString
}

func (s NullString) String() string {
	v, err := s.Value()
	if err != nil {
		return ""
	}
	return v.(string)
}
