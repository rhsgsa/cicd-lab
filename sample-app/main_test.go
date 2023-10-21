package main

import (
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestGenerateMessage(t *testing.T) {
	tables := []struct {
		path           string
		expectedEnding string
	}{
		{"User1", " World"},
		{"/User2", " User2"},
		{"/", " World"},
		{"", " World"},
	}

	for _, table := range tables {
		t.Logf(`Testing with path "%s"`, table.path)
		message := generateMessage(table.path)
		if !strings.HasSuffix(message, table.expectedEnding) {
			t.Errorf(`expected to get a message with suffix "%s" but got this message instead: "%s"`, table.expectedEnding, message)
		}
	}
}

func TestHandler(t *testing.T) {
	tables := []struct {
		uri            string
		expectedSuffix string
	}{
		{"/", "World"},
		{"/User", "User"},
	}

	for _, table := range tables {
		t.Logf(`Testing with uri "%s"`, table.uri)
		testHandlerWithName(t, table.uri, table.expectedSuffix)
	}
}

func testHandlerWithName(t *testing.T, uri string, expectedSuffix string) {
	r := httptest.NewRequest(http.MethodGet, uri, nil)
	w := httptest.NewRecorder()
	handler(w, r)
	res := w.Result()
	defer res.Body.Close()
	b, err := ioutil.ReadAll(res.Body)
	if err != nil {
		t.Errorf("error reading response body: %v", err)
		return
	}
	body := strings.TrimSpace(string(b))
	if !strings.HasSuffix(body, expectedSuffix) {
		t.Errorf("expected response body did not have the expected suffix %s, got this instead: %s", expectedSuffix, body)
	}
}
