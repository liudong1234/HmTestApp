
class URL {
  url: string = '';
}
@Builder
function imageEdge(src: URL) {
  Image(src.url)
    .imageFancy()
}
@Builder
function imagePing(src: URL) {
  Image(src.url)
    .imageFancy()
}

@Extend(Image)
function imageFancy() {
  .width('80%')
  .height(100)
  .alt('tupian')
  .margin(20)
}

const imageBuilder: WrappedBuilder<[URL]>[] = [wrapBuilder(imageEdge), wrapBuilder(imagePing)];

@Component
export struct WrappedBuilderComponent {
  @State url: string = "https://haowallpaper.com/link/common/file/getCroppingImg/17424727189736832";
  @State textColor: Color = Color.Red;
  @State textWidth: number = 80;
  @State switch: boolean = true;

  build() {
    Column() {
      ForEach(imageBuilder, (item: WrappedBuilder<[URL]>) => {
        item.builder({url: this.url})
      })
      Button('切换图片')
        .onClick(() => {
          this.url = 'https://haowallpaper.com/link/common/file/getCroppingImg/17414408731020672';
        })

      Button('1')
        .width(100)
        .height(100)
        .stateStyles({
          focused: {
            .backgroundColor('red')
          },
          pressed: {
            .backgroundColor('ff707070')
          },
          normal: {
            .backgroundColor('red')
          }
        })
        .onClick(() => {
          this.textWidth = this.textWidth == 80 ? 160: 80;
          this.switch = !this.switch;
        })

    }
  }
}