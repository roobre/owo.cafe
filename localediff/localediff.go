package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"slices"
	"strings"

	"github.com/olekukonko/tablewriter"
)

func main() {
	if len(os.Args) != 3 {
		fmt.Fprintf(os.Stderr, "Usage: %s <base json> <override json>", os.Args[0])
		os.Exit(2)
	}

	base, err := unmarshal(os.Args[1])
	if err != nil {
		log.Fatalf("Opening base json: %v", err)
	}

	override, err := unmarshal(os.Args[2])
	if err != nil {
		log.Fatalf("Opening overridejson: %v", err)
	}

	overrideKeys := make([]string, 0, len(override))
	for k := range override {
		overrideKeys = append(overrideKeys, k)
	}
	slices.Sort(overrideKeys)

	tw := tablewriter.NewWriter(os.Stdout)
	tw.SetHeader([]string{"Key", "Base", "Patched"})
	tw.SetRowLine(true)

	for _, key := range overrideKeys {
		tw.Append([]string{key, base[key], override[key]})
	}

	tw.Render()
}

func unmarshal(path string) (map[string]string, error) {
	file, err := get(path)
	if err != nil {
		return nil, fmt.Errorf("opening file %q: %w", path, err)
	}

	out := map[string]string{}
	err = json.NewDecoder(file).Decode(&out)
	return out, err
}

func get(path string) (io.ReadCloser, error) {
	if !strings.HasPrefix(path, "http") {
		return os.Open(path)
	}

	resp, err := http.Get(path)
	if err != nil {
		return nil, err
	}

	return resp.Body, nil
}
