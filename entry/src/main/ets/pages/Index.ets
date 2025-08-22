@Component
struct Child {
  label: string = "Child";

  @Builder
  customTest() {

  }
  @Builder
  specialTest() {

  }

  @BuilderParam customChildBuilder: () => void = this.customTest;
  @BuilderParam specialChildBuilder: () => void = this.specialTest;
  build() {
    Column() {
      this.customChildBuilder()
      this.specialChildBuilder()
    }
  }
}

@Entry
@Component
struct Parent {
  label: string = "Parent";

  @Builder
  functionBuilder() {
    Text(`${this.label}`)
      .fontSize(30)
  }

  build() {
    Column() {
      this.functionBuilder()
      Child({ customChildBuilder: this.functionBuilder, specialChildBuilder: (): void => {this.functionBuilder()} })
    }
  }
}