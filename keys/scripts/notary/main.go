// transparency: Dark Bio transparency reports
// Copyright 2026 Dark Bio AG. All rights reserved.

// Command notary verifies a published notary key and prints its activation time.
package main

import (
	"errors"
	"fmt"
	"math"
	"os"
	"time"

	"github.com/dark-bio/crypto-go/cwt"
	"github.com/dark-bio/crypto-go/cwt/claims"
	"github.com/dark-bio/crypto-go/xdsa"
)

// notaryClaims holds the activation time and key attested by the notary root.
type notaryClaims struct {
	claims.NotBefore
	claims.Confirm[*xdsa.PublicKey]
}

// main reports verification errors on stderr.
func main() {
	if err := verify(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

// verify checks the root signature and the published key, then prints nbf in UTC.
func verify(args []string) error {
	if len(args) != 3 {
		return errors.New("usage: notary <root.xdsa.pub> <key.xdsa.pub> <attestation.cwt>")
	}
	// Read both published keys and the signed attestation
	root, err := readPublicKey(args[0])
	if err != nil {
		return err
	}
	key, err := readPublicKey(args[1])
	if err != nil {
		return err
	}
	token, err := os.ReadFile(args[2])
	if err != nil {
		return err
	}
	// Check the signature and key binding independently of the current time
	att, err := cwt.Verify[notaryClaims](token, root, []byte("notary-attestation-v1"), nil)
	if err != nil {
		return fmt.Errorf("%s: %w", args[2], err)
	}
	if att.Key().Marshal() != key.Marshal() {
		return errors.New("attested cnf key differs from the published notary key")
	}
	// Convert the unsigned claim to Unix seconds before formatting it
	if att.Nbf > math.MaxInt64 {
		return fmt.Errorf("nbf %d exceeds the supported Unix time range", att.Nbf)
	}
	_, err = fmt.Println(time.Unix(int64(att.Nbf), 0).UTC().Format(time.RFC3339))
	return err
}

// readPublicKey decodes a published xDSA public key from PEM.
func readPublicKey(path string) (*xdsa.PublicKey, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	key, err := xdsa.ParsePublicKeyPEM(string(data))
	if err != nil {
		return nil, fmt.Errorf("%s: %w", path, err)
	}
	return key, nil
}
