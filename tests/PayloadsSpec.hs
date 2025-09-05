module PayloadsSpec (spec) where

import Test.Hspec
import Examples.Payloads (matMul)

spec :: Spec
spec = do
  describe "matMul" $ do
    it "computes 2x2 matrix multiplication" $ do
      let a = [[1,2],[3,4]]
          b = [[5,6],[7,8]]
      matMul a b `shouldBe` [[19,22],[43,50]]

    it "works with identity matrix" $ do
      let a = [[1,2],[3,4]]
          i = [[1,0],[0,1]]
      matMul a i `shouldBe` a
