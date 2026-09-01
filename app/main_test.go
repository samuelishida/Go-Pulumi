package main

import (
	"encoding/json"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestEcho(t *testing.T) {
	req := httptest.NewRequest("POST", "/hello?name=world", strings.NewReader("hi"))
	rec := httptest.NewRecorder()
	echo(rec, req)

	if rec.Code != 200 {
		t.Fatalf("got %d, want 200", rec.Code)
	}

	var got map[string]interface{}
	if err := json.Unmarshal(rec.Body.Bytes(), &got); err != nil {
		t.Fatal(err)
	}
	if got["path"] != "/hello" {
		t.Errorf("path = %v, want /hello", got["path"])
	}
	if got["body"] != "hi" {
		t.Errorf("body = %v, want hi", got["body"])
	}
}

func TestEchoEmptyBody(t *testing.T) {
	req := httptest.NewRequest("GET", "/", nil)
	rec := httptest.NewRecorder()
	echo(rec, req)

	if rec.Code != 200 {
		t.Fatalf("got %d, want 200", rec.Code)
	}
}