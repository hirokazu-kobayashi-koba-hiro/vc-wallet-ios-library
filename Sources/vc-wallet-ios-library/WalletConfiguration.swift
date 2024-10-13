//
//  WalletConfiguration.swift
//  VcWalletLibrary
//
//  Created by 小林弘和 on 2024/10/12.
//

public class WalletConfiguration {

  let privateKey: String

  public init() {
    //FIXME
    self.privateKey = """
      {"crv":"P-256","d":"yd6RKZJfgpkeArPMK1EpZ0MMM3BzHJh0Gwkb3rG8t5o","kid":"9ACCF5A3-8691-443E-B3D5-9D03B94F741C","kty":"EC","x":"NEkkjPB7JavPAB2pF7eMixI4njznCD67WL2lGyMVfyI","y":"jt_p1VJgEUs_fN9zrh7DgatO14cG95Wuma8J7vVcrew"}
      """
  }
}
