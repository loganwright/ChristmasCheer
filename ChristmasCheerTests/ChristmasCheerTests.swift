//
//  ChristmasCheerTests.swift
//  ChristmasCheerTests
//
//  Created by Logan Wright on 11/21/14.
//  Copyright (c) 2014 lowriDevs. All rights reserved.
//

import UIKit
import XCTest

extension String: Error {}

struct Networking {
    static func post<E: Encodable, D: Decodable>(_ e: E, to url: String, expect: D.Type, completion: @escaping (Result<D, Error>) -> Void) {
        let body: Data
        do { body = try JSONEncoder().encode(e) }
        catch {
            completion(.failure(error))
            return
        }

        Networking.send("POST", to: url, body: body) { result in
            switch result {
            case .success(let resp):
                guard let data = resp.data else {
                    completion(.failure("expected data on response: \(resp.http)"))
                    return
                }

                do {
                    let object = try JSONDecoder().decode(D.self, from: data)
                    completion(.success(object))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    static func send(_ method: String,
                     to _url: String,
                     headers: [String: String] = ["Content-Type": "application/json"],
                     body: Data? = nil,
                     completion: @escaping (Result<NetworkResponse, Error>) -> Void) {

        guard let url = URL(string: _url) else {
             completion(.failure("unable to make url from \(_url)"))
             return
         }

        var request = URLRequest(url: url)
        request.httpMethod = method

        headers.forEach { field, value in
            request.setValue(value, forHTTPHeaderField: field)
        }
        request.httpBody = body

         URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            } else if let response = response {
                completion(.success(.init(response: response, data: data)))
            } else {
                completion(.failure("no error, or response, idk.."))
            }
         }
         .resume()
    }
}

struct NetworkResponse {
    let http: URLResponse
    let data: Data?
}

struct Backend {
    static func makeUser(name: String) {
        
    }
}

class ChristmasCheerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
//        let singles = unfiltered.components(separatedBy: " ").filter { $0.count == 1 }
//        print(singles)


        func relate(a: Character, b: Character) {
            guard let aidx = alphabet.firstIndex(of: a),
                let bidx = alphabet.firstIndex(of: b) else { return }
            print("\(a):\(aidx)\n\(b):\(bidx)")
            print("** \(aidx - bidx)")
        }

        func zip(l: String, r: String) -> [Character: Character] {
            let l = Array(l.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
            let r = Array(r.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())

            var key: [Character: Character] = [:]
            for i in 0..<r.count {
                let lc = l[i]
                let rc = r[i]
                key[lc] = rc
            }
            return key
        }

        pairs.map(zip).forEach {
            $0.forEach(relate)
            print()
        }

//        key.forEach(relate)

        var filtered = [Character]()

        unfiltered.forEach { char in
            let replaced = key[char] ?? char
            filtered.append(replaced)
        }

        print(String(filtered))
        print("")
    }

    
    func testPerformanceExample() {
    }


    
}

let pairs: [String: String] = [
    "HER MOST MEMORABLE SONGS INCLUDE ALL I WANNA DO MY FAVORITE MISTAKE AND THE THEME TO TOMORROW NEVER DIES": "BCP YIKW YCYIPZGDC KIMJK XMADVQC ZDD X RZMMZ QI YL UZEIPXWC YXKWZOC ZMQ WBC WBCYC WI WIYIPPIR MCECP QXCK"
]


let unfiltered = """
WBMP PMWGXD UGWXO QIGUDI U GXTWOXJIOPMUA ZMESOI QIGUSPI XZ WBI PXOKMK
TUWSOI XZ BMP BXDMGMKI, GXJIOIK MT WBI ZMAD USWX ZXGSP.
CVGU QIPVGCNPC GU INUSKOUGZDN MKI INZTGDAGOE YQOL KM DKOAKO’U
HKOAIKTU PQCVNAIQDU QMCNI CVN EINQC MGIN, GOPDTAGOE UC. SQTD’U.
APXR ITXAXRP RSTMXMEFXRA XR IVRA YDCJD GCT E AM RPCJ WED MR. JXFZ.
BCP YIKW YCYIPZGDC KIMJK XMADVQC “ZDD X RZMMZ QI,” “YL UZEIPXWC
YXKWZOC,” ZMQ WBC WBCYC WI WIYIPPIR MCECP QXCK.
IASC WUMC BASH ENSUWBE HWUPX EVVSEUSJ MC XAS HMMJ CSXIMUR, PAS IEP
XAS MCKD HSNEKS WUMC BASH.
BDOP PGQJUC QOBH RMEAUEP RKKGRIGC OU ARIP RBBRQXP!, BDIGG RAOFJP!,
RUC KEIG MEQX, RUC OP QEIIGUBMH BJEIOUF TOBD R ZRUYJ KMRHGI TDJ QJEMC
DRNG ZGGU EPGC VJI BDOP QMEG OUPBGRC!
RQ IOE URQ NDHEU XOCPH AQOSYQ GDULRQH EDKLQ 1915 UP IDK UIP RYKBHQB
SOXQE ZF URQ OSQ PN URDHUF-PKQ.
UDZ OMX H XMKZC TWENZ EX CEQZWHQAWZ BMW DZW GZTEPQEMX MB TZHUHXQ CEBZ
EX PDEXH, HXG UTZXQ THWQ MB DZW CEBZ HGRMPHQEXF BMW HGMTQEXF HUEHX
HXG YEJZG-WHPZ IEGU.
EQNW EHJ-SRBFPX OHTCPS QHTXW BKZPSHKW UHSTX SPAHSXW, NBATKXNBO
DHKBOPWE UNBBPS HC EQP K.W. ZRWEPSW RBX QNOQPWE RBBKRT PRSBNBOW CHS R
OHTCPS.
""".lowercased()

let alphabet = Array("abcdefghijklmnopqrstuvwxyz")

// [From: To]
let key: [Character: Character] = [
    "x": "i",
    "z": "t",
    "u": "a",
    "k": "e",
    "w": "g",
    "f": "o"
]

